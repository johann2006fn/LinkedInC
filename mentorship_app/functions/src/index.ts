import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { GoogleGenerativeAI } from "@google/generative-ai";

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// 1. AUTH HOOK: onUserSignUp
//    Trigger: Automatically runs when a new Firebase Auth user is created.
//    Purpose: Creates a skeleton Firestore profile so the app feels instant.
// ---------------------------------------------------------------------------
export const onUserSignUp = functions.auth.user().onCreate(async (user) => {
    const { uid, email, displayName, photoURL } = user;

    const userDoc: Record<string, unknown> = {
        name: displayName || "",
        email: email || "",
        role: null, // Will be set during role-selection onboarding
        profileImageUrl: photoURL || null,
        subtitle: null,
        tags: [],
        experience: null,
        mentees: null,
        collegeCode: null,
        bio: null,
        skills: [],
        interests: [],
        goals: [],
        department: null,
        year: null,
        isProfileComplete: false,
        gender: null,
        preferences: null,
        onboardingCompletedAt: null,
        acceptingMentees: false,
        maxMentees: 3,
        profileEmbedding: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("users").doc(uid).set(userDoc, { merge: true });
    functions.logger.info(`Created profile for new user: ${uid}`);
});

// ---------------------------------------------------------------------------
// 2. ONBOARDING ENGINE: generateProfileEmbedding
//    Trigger: Firestore onUpdate on users/{userId}
//    Purpose: Converts goals/skills text → Gemini embedding vector
// ---------------------------------------------------------------------------
export const generateProfileEmbedding = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const prevData = change.before.data();

        // Only run when goals or skills actually change (prevents infinite loops)
        const goalsChanged =
            JSON.stringify(newData.goals) !== JSON.stringify(prevData.goals);
        const skillsChanged =
            JSON.stringify(newData.skills) !== JSON.stringify(prevData.skills);
        const bioChanged = newData.bio !== prevData.bio;

        if (!goalsChanged && !skillsChanged && !bioChanged) {
            return null;
        }

        const userId = context.params.userId;
        const isMentor = newData.role === "mentor";

        // Build the text to embed
        const profileText = isMentor
            ? `Expertise: ${(newData.skills || []).join(", ")}. Bio: ${newData.bio || ""}`
            : `Goals: ${(newData.goals || []).join(", ")}. Bio: ${newData.bio || ""}`;

        if (!profileText.trim() || profileText.length < 5) return null;

        try {
            const apiKey = process.env.GEMINI_API_KEY;
            if (!apiKey) {
                functions.logger.error("GEMINI_API_KEY not set in Firebase config");
                return null;
            }

            const genAI = new GoogleGenerativeAI(apiKey);
            const model = genAI.getGenerativeModel({ model: "embedding-001" });

            const result = await model.embedContent(profileText);
            const embedding = result.embedding.values;

            await change.after.ref.update({
                profileEmbedding: embedding,
            });

            functions.logger.info(
                `Generated embedding (${embedding.length} dims) for user: ${userId}`
            );
            return null;
        } catch (error) {
            functions.logger.error("Error generating embedding:", error);
            return null;
        }
    });

// ---------------------------------------------------------------------------
// 3. CORE ALGORITHM: getDailyMatches
//    Trigger: HTTPS Callable (client app calls this)
//    Purpose: Hard filter → Cosine similarity → Top 3 matches
// ---------------------------------------------------------------------------
export const getDailyMatches = functions.https.onCall(async (data, context) => {
    // Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be signed in."
        );
    }

    const menteeId = context.auth.uid;

    // 1. Get the mentee's profile
    const menteeDoc = await db.collection("users").doc(menteeId).get();
    if (!menteeDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Mentee profile not found.");
    }

    const mentee = menteeDoc.data()!;
    const menteeEmbedding = mentee.profileEmbedding as number[] | null;

    // 2. Hard Filter: Get all available mentors (optionally same college)
    let query: admin.firestore.Query = db
        .collection("users")
        .where("role", "==", "mentor")
        .where("acceptingMentees", "==", true)
        .where("isProfileComplete", "==", true);

    // Apply college code filter if the mentee has one
    if (mentee.collegeCode) {
        query = query.where("collegeCode", "==", mentee.collegeCode);
    }

    const mentorsSnap = await query.limit(50).get();

    if (mentorsSnap.empty) {
        return { matches: [], message: "No available mentors found." };
    }

    // 3. Apply gender preference filter
    const connectWith = mentee.preferences?.connectWith;
    let mentors = mentorsSnap.docs
        .map((doc) => ({ id: doc.id, ...doc.data() }))
        .filter((m: any) => m.id !== menteeId);

    if (connectWith === "Same gender" && mentee.gender) {
        mentors = mentors.filter((m: any) => m.gender === mentee.gender);
    }

    // 4. Vector Search: Cosine Similarity
    if (menteeEmbedding && menteeEmbedding.length > 0) {
        const scored = mentors
            .map((mentor: any) => {
                const mentorEmb = mentor.profileEmbedding as number[] | null;
                if (!mentorEmb || mentorEmb.length !== menteeEmbedding.length) {
                    return { mentor, score: 0 };
                }
                const score = cosineSimilarity(menteeEmbedding, mentorEmb);
                return { mentor, score };
            })
            .sort((a, b) => b.score - a.score);

        const top3 = scored.slice(0, 3).map((item) => ({
            id: item.mentor.id,
            name: (item.mentor as any).name,
            email: (item.mentor as any).email,
            role: (item.mentor as any).role,
            profileImageUrl: (item.mentor as any).profileImageUrl,
            subtitle: (item.mentor as any).subtitle,
            skills: (item.mentor as any).skills,
            bio: (item.mentor as any).bio,
            matchPercentage: Math.round(item.score * 100),
        }));

        return { matches: top3 };
    }

    // Fallback: return first 3 mentors with no score
    const fallback = mentors.slice(0, 3).map((m: any) => ({
        id: m.id,
        name: m.name,
        email: m.email,
        role: m.role,
        profileImageUrl: m.profileImageUrl,
        subtitle: m.subtitle,
        skills: m.skills,
        bio: m.bio,
        matchPercentage: 50,
    }));

    return { matches: fallback };
});

// ---------------------------------------------------------------------------
// 4. FRICTIONLESS CHAT: generateIcebreaker
//    Trigger: Firestore onUpdate on connections/{connectionId}
//    Purpose: When a mentor accepts → create a chat room with AI first message
// ---------------------------------------------------------------------------
export const generateIcebreaker = functions.firestore
    .document("connections/{connectionId}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const prevData = change.before.data();

        // Only trigger when status changes from pending → accepted
        if (prevData.status === "accepted" || newData.status !== "accepted") {
            return null;
        }

        const mentorId = newData.mentorId;
        const studentId = newData.studentId;

        try {
            // Get both user profiles
            const [mentorDoc, studentDoc] = await Promise.all([
                db.collection("users").doc(mentorId).get(),
                db.collection("users").doc(studentId).get(),
            ]);

            const mentor = mentorDoc.data();
            const student = studentDoc.data();
            if (!mentor || !student) return null;

            // Create chat room
            const chatRef = await db.collection("chats").add({
                participantIds: [mentorId, studentId],
                lastMessage: "",
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                otherUserName: "",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Generate icebreaker with Gemini
            const apiKey = process.env.GEMINI_API_KEY;
            if (apiKey) {
                const genAI = new GoogleGenerativeAI(apiKey);
                const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

                const prompt = `Write a casual, friendly 1-sentence opening message from a mentee to their new mentor based on shared interests. The mentee's goals: "${(student.goals || []).join(", ")}". The mentor's expertise: "${(mentor.skills || []).join(", ")}". Keep it warm, brief, and specific. Only output the message text, nothing else.`;

                const result = await model.generateContent(prompt);
                const icebreaker = result.response.text() || "Hi! Excited to connect with you! 🚀";

                // Save the AI-generated message as a draft in the chat
                await chatRef.collection("messages").add({
                    chatId: chatRef.id,
                    senderId: studentId,
                    content: icebreaker,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    isDraft: true, // User can edit before sending
                });

                await chatRef.update({
                    lastMessage: icebreaker,
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            functions.logger.info(
                `Created chat room ${chatRef.id} for connection ${context.params.connectionId}`
            );
            return null;
        } catch (error) {
            functions.logger.error("Error generating icebreaker:", error);
            return null;
        }
    });

// ---------------------------------------------------------------------------
// UTILITY: Cosine Similarity
// ---------------------------------------------------------------------------
function cosineSimilarity(a: number[], b: number[]): number {
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < a.length; i++) {
        dotProduct += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }

    const denominator = Math.sqrt(normA) * Math.sqrt(normB);
    return denominator === 0 ? 0 : dotProduct / denominator;
}
