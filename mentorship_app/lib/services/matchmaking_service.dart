import 'dart:async';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

/// Fully client-side matchmaking service powered by Gemini.
/// Replaces Cloud Functions — works on Firebase Spark (free) plan.
///
/// Provides:
///   1. Profile embedding generation (Gemini text-embedding-004)
///   2. Public cosine similarity calculation
///   3. findTopMentors — vector-ranked mentor list for a given student
///   4. getDailyMatches — full pipeline with hard filters + gender pref
///   5. AI icebreaker generation (gemini-2.0-flash)
///   6. Prompt-based fallback matching (for profiles without embeddings)
class MatchmakingService {
  // API key is injected at build time via --dart-define=GEMINI_API_KEY=<key>
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final FirebaseFirestore _firestore;
  late final GenerativeModel _chatModel;
  late final GenerativeModel _embeddingModel;

  MatchmakingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _chatModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
    );
    _embeddingModel = GenerativeModel(
      model: 'text-embedding-004',
      apiKey: _apiKey,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. EMBEDDING GENERATION
  //    Called after onboarding is complete. Converts profile text → vector.
  //    userData must contain at minimum 'bio' and 'goals' keys.
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a Gemini content embedding for a user's profile
  /// and saves it to the user's Firestore document.
  ///
  /// [userId]   — Firestore document ID in the 'users' collection.
  /// [userData] — The user's data map; must contain 'bio' (String?)
  ///              and 'goals' (List or String?).
  Future<void> generateAndSaveEmbedding(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    // ── Build profile text from bio + goals + skills ─────────────────────
    final bio = (userData['bio'] as String?)?.trim() ?? '';
    
    final goalsRaw = userData['goals'];
    final goals = goalsRaw is List
        ? goalsRaw.cast<String>().join(', ')
        : (goalsRaw as String?)?.trim() ?? '';

    final skillsRaw = userData['skills'];
    final skills = skillsRaw is List
        ? skillsRaw.cast<String>().join(', ')
        : (skillsRaw as String?)?.trim() ?? '';

    final profileText = [
      if (bio.isNotEmpty) bio,
      if (goals.isNotEmpty) 'Goals: $goals',
      if (skills.isNotEmpty) 'Skills: $skills',
    ].join('. ');

    if (profileText.length < 5) return; // nothing meaningful to embed

    try {
      final result = await _embeddingModel.embedContent(
        Content.text(profileText),
      );
      final embedding = result.embedding.values;

      await _firestore.collection('users').doc(userId).update({
        'profileEmbedding': embedding,
      }).timeout(const Duration(seconds: 10));
      print('DEBUG: [Save Profile Embedding] Successful');
    } on TimeoutException {
      throw Exception('Network timeout. Please check your connection and try again.');
    } catch (e, stackTrace) {
      print('ERROR: Failed at [Save Profile Embedding] - $e\n$stackTrace');
      // Silently fail — embeddings are optional; prompt fallback will work
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. COSINE SIMILARITY  (public — can be used by tests or other widgets)
  // ─────────────────────────────────────────────────────────────────────────

  /// Calculates the cosine similarity between two vectors.
  ///
  /// Returns a [double] in the range [-1, 1] where:
  ///   1.0  = identical direction (perfect match)
  ///   0.0  = orthogonal (no relation)
  ///  -1.0  = opposite direction
  ///
  /// Returns 0.0 if either vector has zero magnitude (safe divide-by-zero).
  static double calculateCosineSimilarity(List<double> vecA, List<double> vecB) {
    assert(vecA.length == vecB.length,
        'Vectors must be the same length: ${vecA.length} vs ${vecB.length}');

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    return denominator == 0 ? 0.0 : dotProduct / denominator;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. FIND TOP MENTORS (Vector-similarity ranked)
  //    Fetches the student's embedding, scores all mentors, returns sorted list.
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a ranked list of the best-matching mentors for [studentId],
  /// sorted by cosine similarity (highest first).
  ///
  /// [studentId] — Firestore UID of the student.
  /// [limit]     — Maximum number of mentors to return (default 5).
  ///
  /// Throws a [StateError] if the student document has no embedding yet.
  /// Call [generateAndSaveEmbedding] first if needed.
  Future<List<AppUser>> findTopMentors(
    String studentId, {
    int limit = 5,
  }) async {
    // ── 1. Fetch student embedding ────────────────────────────────────────
    final studentDoc =
        await _firestore.collection('users').doc(studentId).get();
    if (!studentDoc.exists) {
      throw StateError('Student document not found: $studentId');
    }

    final studentData = studentDoc.data()!;
    final rawEmbedding = studentData['profileEmbedding'] as List?;

    if (rawEmbedding == null || rawEmbedding.isEmpty) {
      throw StateError(
        'Student $studentId has no profileEmbedding. '
        'Call generateAndSaveEmbedding() first.',
      );
    }

    final studentVec =
        rawEmbedding.map((e) => (e as num).toDouble()).toList();

    // ── 2. Fetch all mentors ───────────────────────────────────────────────
    final mentorsSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .limit(50)
        .get();

    if (mentorsSnap.docs.isEmpty) return [];

    // ── 3. Score each mentor by cosine similarity ─────────────────────────
    final scored = <MapEntry<AppUser, double>>[];

    for (final doc in mentorsSnap.docs) {
      // Skip the student themselves (edge case where a user is both)
      if (doc.id == studentId) continue;

      final mentor = AppUser.fromFirestore(doc);
      final mentorVec = mentor.profileEmbedding;

      double score = 0.0;
      if (mentorVec != null &&
          mentorVec.isNotEmpty &&
          mentorVec.length == studentVec.length) {
        score = MatchmakingService.calculateCosineSimilarity(studentVec, mentorVec);
      }

      scored.add(MapEntry(mentor, score));
    }

    // ── 4. Sort descending by score ───────────────────────────────────────
    scored.sort((a, b) => b.value.compareTo(a.value));

    // ── 5. Return top [limit] mentors with matchScore attached ────────────
    return scored
        .take(limit)
        .map((entry) => entry.key.copyWith(
              matchScore: (entry.value * 100).round(),
            ))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. DAILY MATCHES (Primary: Vector Search | Fallback: Prompt)
  //    Hard filter → cosine similarity → Top 3
  //    Keeps existing behaviour; internally uses calculateCosineSimilarity.
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the top [topK] mentor matches for the currently signed-in user.
  /// Uses vector similarity when embeddings exist, otherwise falls back to
  /// Gemini prompt-based ranking.
  Future<List<AppUser>> getDailyMatches({int topK = 3}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final menteeDoc = await _firestore.collection('users').doc(uid).get();
    if (!menteeDoc.exists) return [];

    final mentee = AppUser.fromFirestore(menteeDoc);

    // ── Hard Filter ──────────────────────────────────────────────────────
    Query query = _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .where('isProfileComplete', isEqualTo: true);

    // Same college filter (if applicable)
    if (mentee.collegeCode != null && mentee.collegeCode!.isNotEmpty) {
      query = query.where('collegeCode', isEqualTo: mentee.collegeCode);
    }

    final mentorsSnap = await query.limit(50).get();
    if (mentorsSnap.docs.isEmpty) return [];

    var mentors = mentorsSnap.docs
        .map((doc) => AppUser.fromFirestore(doc))
        .where((m) => m.id != uid)
        .toList();

    // ── Gender Preference ────────────────────────────────────────────────
    final connectWith = mentee.preferences?['connectWith'];
    if (connectWith == 'Same gender' && mentee.gender != null) {
      mentors = mentors.where((m) => m.gender == mentee.gender).toList();
    }

    if (mentors.isEmpty) return [];

    // ── Vector Search (if embeddings exist) ──────────────────────────────
    if (mentee.profileEmbedding != null &&
        mentee.profileEmbedding!.isNotEmpty) {
      final scored = mentors.map((mentor) {
        if (mentor.profileEmbedding == null ||
            mentor.profileEmbedding!.length !=
                mentee.profileEmbedding!.length) {
          return MapEntry(mentor, 0.0);
        }
        final score = MatchmakingService.calculateCosineSimilarity(
          mentee.profileEmbedding!,
          mentor.profileEmbedding!,
        );
        return MapEntry(mentor, score);
      }).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return scored
          .take(topK)
          .map((e) => e.key.copyWith(
                matchScore: (e.value * 100).round(),
              ))
          .toList();
    }

    // ── Prompt Fallback (no embeddings yet) ──────────────────────────────
    return _promptBasedMatch(mentee, mentors, topK: topK);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. ICEBREAKER GENERATION
  //    Called when a connection is accepted → AI-writes a first message.
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates an AI-powered opening message based on shared interests.
  Future<String> generateIcebreaker({
    required AppUser mentee,
    required AppUser mentor,
  }) async {
    try {
      final prompt =
          'Write a casual, friendly 1-sentence opening message from a mentee '
          'to their new mentor based on shared interests. '
          'Mentee goals: "${mentee.goals.join(", ")}". '
          'Mentor expertise: "${mentor.skills.join(", ")}". '
          'Keep it warm, brief, and specific. Only output the message text.';

      final response = await _chatModel.generateContent([Content.text(prompt)]);
      print('DEBUG: [Generate Icebreaker] Successful');
      return response.text ?? 'Hi! Excited to connect with you! 🚀';
    } catch (e, stackTrace) {
      print('ERROR: Failed at [Generate Icebreaker] - $e\n$stackTrace');
      return 'Hi! Excited to connect with you! 🚀';
    }
  }

  /// Creates a chat room between two users with an optional AI icebreaker.
  Future<String?> createChatWithIcebreaker({
    required String mentorId,
    required String studentId,
  }) async {
    try {
      // Get both profiles
      final mentorDoc =
          await _firestore.collection('users').doc(mentorId).get();
      final studentDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (!mentorDoc.exists || !studentDoc.exists) return null;

      final mentor = AppUser.fromFirestore(mentorDoc);
      final student = AppUser.fromFirestore(studentDoc);

      // Create the chat room
      final chatRef = await _firestore.collection('chats').add({
        'participantIds': [mentorId, studentId],
        'lastMessage': '',
        'lastUpdated': FieldValue.serverTimestamp(),
        'otherUserName': '',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      // Generate icebreaker
      final icebreaker = await generateIcebreaker(
        mentee: student,
        mentor: mentor,
      );

      // Save as a draft message
      await chatRef.collection('messages').add({
        'chatId': chatRef.id,
        'senderId': studentId,
        'content': icebreaker,
        'timestamp': FieldValue.serverTimestamp(),
        'isDraft': true,
      }).timeout(const Duration(seconds: 10));

      await chatRef.update({
        'lastMessage': icebreaker,
        'lastUpdated': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      print('DEBUG: [Create Chat with Icebreaker] Successful');
      return chatRef.id;
    } on TimeoutException {
      throw Exception('Network timeout. Please check your connection and try again.');
    } catch (e, stackTrace) {
      print('ERROR: Failed at [Create Chat with Icebreaker] - $e\n$stackTrace');
      throw Exception('Failed to create chat with icebreaker: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE: Prompt-based Fallback Matching (Gemini Chat API)
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<AppUser>> _promptBasedMatch(
    AppUser mentee,
    List<AppUser> mentors, {
    int topK = 3,
  }) async {
    try {
      final menteeDesc = mentee.toMatchingDescription();
      final mentorListText = mentors
          .asMap()
          .entries
          .map((e) => 'MENTOR ${e.key + 1}:\n${e.value.toMatchingDescription()}')
          .join('\n---\n');

      final prompt = '''
You are an intelligent mentor-matching algorithm for a college mentorship app.

MENTEE PROFILE:
$menteeDesc

AVAILABLE MENTORS:
$mentorListText

TASK:
Rank all the mentors from best to worst match for this mentee.
Respond ONLY with a JSON array of mentor numbers in order, and a brief reason for each.

Format:
[
  {"rank": 1, "mentorNumber": <number>, "score": <1-100>, "reason": "<short reason>"},
  ...
]

Consider: shared interests, complementary skills, goals alignment, and department similarity.
Be concise. Only output valid JSON.
''';

      final response =
          await _chatModel.generateContent([Content.text(prompt)]);
      final rawText = response.text ?? '';

      print('DEBUG: [Prompt Based Match] Successful');
      return _parseGeminiResponse(rawText, mentors).take(topK).toList();
    } catch (e, stackTrace) {
      print('ERROR: Failed at [Prompt Based Match] - $e\n$stackTrace');
      // Return unranked mentors as absolute fallback
      return mentors.take(topK).toList();
    }
  }

  List<AppUser> _parseGeminiResponse(String rawText, List<AppUser> mentors) {
    try {
      final jsonStart = rawText.indexOf('[');
      final jsonEnd = rawText.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) return mentors;

      final jsonStr = rawText.substring(jsonStart, jsonEnd + 1);
      final ranked = <AppUser>[];
      final entries =
          RegExp(r'"mentorNumber"\s*:\s*(\d+).*?"score"\s*:\s*(\d+)')
              .allMatches(jsonStr);

      for (final match in entries) {
        final mentorNum = int.tryParse(match.group(1) ?? '') ?? 0;
        final score = int.tryParse(match.group(2) ?? '') ?? 0;
        if (mentorNum >= 1 && mentorNum <= mentors.length) {
          final mentor = mentors[mentorNum - 1];
          ranked.add(mentor.copyWith(matchScore: score));
        }
      }

      return ranked.isEmpty ? mentors : ranked;
    } catch (e, stackTrace) {
      print('ERROR: Failed at [Parse Gemini Response] - $e\n$stackTrace');
      return mentors;
    }
  }
}
