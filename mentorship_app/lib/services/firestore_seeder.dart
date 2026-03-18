import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seeds only the sample mentor users (safe to re-run, checks by name).
  Future<void> seedSampleMentors() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final mentors = [
      {
        'name': 'Vikram Singh',
        'role': 'mentor',
        'subtitle': 'SR. ENGINEER',
        'tags': ['Java', 'System Design'],
        'experience': '8y',
        'mentees': '50+',
        'email': 'vikram@demo.com',
        'isProfileComplete': true,
        'acceptingMentees': true,
        'bio': 'Senior engineer with 8 years in backend systems.',
        'skills': ['Java', 'System Design', 'Microservices'],
        'interests': ['Architecture', 'Mentoring'],
        'goals': ['Give back to community', 'Grow mentees'],
        'matchScore': 0,
      },
      {
        'name': 'Priya Sharma',
        'role': 'mentor',
        'subtitle': 'ALUMNI, CS',
        'tags': ['Python', 'AI/ML'],
        'experience': '3y',
        'mentees': '120+',
        'email': 'priya@demo.com',
        'isProfileComplete': true,
        'acceptingMentees': true,
        'bio': 'AI/ML practitioner and CS alumna.',
        'skills': ['Python', 'TensorFlow', 'Data Science'],
        'interests': ['AI Research', 'Open Source'],
        'goals': ['Help newcomers in AI', 'Build community'],
        'matchScore': 0,
      },
      {
        'name': 'Ananya Iyer',
        'role': 'mentor',
        'subtitle': 'FULL STACK LEAD',
        'tags': ['React', 'Node.js'],
        'experience': '12y',
        'mentees': '200+',
        'email': 'ananya@demo.com',
        'isProfileComplete': true,
        'acceptingMentees': true,
        'bio': 'Full stack lead who loves building products.',
        'skills': ['React', 'Node.js', 'TypeScript'],
        'interests': ['Product Development', 'Startups'],
        'goals': ['Nurture junior developers'],
        'matchScore': 0,
      },
      {
        'name': 'Rohan Gupta',
        'role': 'mentor',
        'subtitle': 'DATA SCIENTIST',
        'tags': ['Data Science', 'Python'],
        'experience': '5y',
        'mentees': '80+',
        'email': 'rohan@demo.com',
        'isProfileComplete': true,
        'acceptingMentees': true,
        'bio': 'Data scientist specialising in NLP and ML.',
        'skills': ['Python', 'PyTorch', 'NLP'],
        'interests': ['Machine Learning', 'Research'],
        'goals': ['Share practical ML knowledge'],
        'matchScore': 0,
      },
      {
        'name': 'Prof. Rajesh Khanna',
        'role': 'mentor',
        'subtitle': 'Computer Science • PhD, Stanford',
        'tags': ['AI/ML', 'Data Science'],
        'experience': '15y',
        'mentees': '300+',
        'email': 'rajesh@demo.com',
        'isProfileComplete': true,
        'acceptingMentees': true,
        'bio': 'Professor of CS with research in ML and data systems.',
        'skills': ['AI/ML', 'Data Science', 'Research'],
        'interests': ['Academic Research', 'Teaching'],
        'goals': ['Train next-gen researchers'],
        'matchScore': 0,
      },
    ];

    final batch = _db.batch();
    final newMentorIds = <String>[];

    for (final mentor in mentors) {
      // Only add if not already there (match by email)
      final existing = await _db
          .collection('users')
          .where('email', isEqualTo: mentor['email'])
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        final ref = _db.collection('users').doc();
        batch.set(ref, mentor);
        newMentorIds.add(ref.id);
      }
    }

    await batch.commit();

    // Re-fetch mentor ids (including ones that already existed)
    final allMentors = await _db
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .limit(5)
        .get();

    final mentorIds = allMentors.docs.map((d) => d.id).toList();
    if (mentorIds.length < 2) return; // Not enough mentors

    // Seed sessions for the current user
    await _db.collection('sessions').add({
      'mentorId': mentorIds.last,
      'studentId': uid,
      'topic': 'Career Path Guidance',
      'mentorName': allMentors.docs.last.data()['name'] ?? 'Mentor',
      'scheduledTime': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 2)),
      ),
      'status': 'upcoming',
    });

    await _db.collection('sessions').add({
      'mentorId': mentorIds.first,
      'studentId': uid,
      'topic': 'System Design Basics',
      'mentorName': allMentors.docs.first.data()['name'] ?? 'Mentor',
      'scheduledTime': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 3)),
      ),
      'status': 'upcoming',
    });

    // Seed a community post from one of the mentors
    final existingPosts = await _db
        .collection('community_posts')
        .limit(1)
        .get();
    if (existingPosts.docs.isEmpty) {
      await _db.collection('community_posts').add({
        'authorId': mentorIds.first,
        'authorName': allMentors.docs.first.data()['name'] ?? 'Mentor',
        'content':
            '🚀 Excited to be here! For all mentees: focus on the fundamentals — strong problem-solving skills will take you further than any framework. Happy to answer questions!',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 3)),
        ),
        'likesCount': 12,
      });

      await _db.collection('community_posts').add({
        'authorId': mentorIds.last,
        'authorName': allMentors.docs.last.data()['name'] ?? 'Mentor',
        'content':
            '📚 Resource of the week: "Designing Data-Intensive Applications" by Martin Kleppmann. Must-read for anyone interested in backend systems and distributed computing.',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'likesCount': 24,
      });
    }
  }

  /// Legacy seedAll kept for compatibility — now delegates to seedSampleMentors.
  Future<void> seedAll() => seedSampleMentors();

  /// Seeds specifically for Mentor Dashboard testing (Creates dummy mentees, connections, and sessions)
  Future<void> seedMentorData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final batch = _db.batch();

    // 1. Create a dummy mentee user
    final dummyMenteeRef = _db.collection('users').doc();
    batch.set(dummyMenteeRef, {
      'name': 'Alex Student (Test)',
      'role': 'mentee',
      'email': 'alex@test.com',
      'subtitle': 'Computer Science, Junior',
      'bio': 'Looking to learn more about mobile dev.',
      'tags': ['Flutter', 'Mobile App'],
    });

    // 2. Create a pending connection request
    final connRef = _db.collection('connections').doc();
    batch.set(connRef, {
      'mentorId': uid,
      'studentId': dummyMenteeRef.id,
      'studentName': 'Alex Student (Test)',
      'note':
          'Hi! I saw your profile and would love to get some guidance on Flutter architecture.',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Create a scheduled session for Today
    final sessionRef1 = _db.collection('sessions').doc();
    batch.set(sessionRef1, {
      'mentorId': uid,
      'mentorName': 'Me (Mentor)',
      'studentId': dummyMenteeRef.id,
      'studentName': 'Alex Student (Test)',
      'topic': 'Resume Review & App Architecture',
      'status': 'upcoming',
      'scheduledTime': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 1)),
      ),
    });

    // 4. Create a scheduled session for Tomorrow
    final sessionRef2 = _db.collection('sessions').doc();
    batch.set(sessionRef2, {
      'mentorId': uid,
      'mentorName': 'Me (Mentor)',
      'studentId': dummyMenteeRef.id,
      'studentName': 'Alex Student (Test)',
      'topic': 'Mock Interview: System Design',
      'status': 'upcoming',
      'scheduledTime': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 1, hours: 2)),
      ),
    });

    await batch.commit();
  }
}
