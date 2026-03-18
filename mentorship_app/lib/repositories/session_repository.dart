import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session.dart';

class SessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Session>> getUpcomingSessions(String userId) {
    return _firestore
        .collection('sessions')
        .where(
          Filter.or(
            Filter('studentId', isEqualTo: userId),
            Filter('mentorId', isEqualTo: userId),
          ),
        )
        .where('status', whereIn: ['upcoming', 'confirmed'])
        .orderBy('scheduledTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Session.fromFirestore(doc))
              .toList();
        });
  }

  Future<String> createSession(Session session) async {
    try {
      final docRef = await _firestore
          .collection('sessions')
          .add(session.toMap())
          .timeout(const Duration(seconds: 10));
      return docRef.id;
    } on TimeoutException {
      throw Exception(
        'Network timeout. Please check your connection and try again.',
      );
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  Future<List<Session>> getMentorSessionsForDate(
    String mentorId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('sessions')
        .where('mentorId', isEqualTo: mentorId)
        .where('status', whereIn: ['upcoming', 'confirmed', 'ongoing'])
        .where('scheduledTime', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledTime', isLessThan: endOfDay)
        .get();

    return snapshot.docs.map((doc) => Session.fromFirestore(doc)).toList();
  }

  Future<void> updateSessionStatus(String sessionId, String status) async {
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .update({'status': status});
  }

  Future<void> completeSession(String sessionId, int duration) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'completed',
      'duration': duration,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Session?> getSessionStream(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? Session.fromFirestore(doc) : null);
  }

  Future<void> updatePresence(
    String sessionId,
    String userId,
    bool isInCall,
  ) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'presence.$userId': isInCall,
    });
  }
}
