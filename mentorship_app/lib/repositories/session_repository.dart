import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session.dart';

class SessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Session>> getUpcomingSessions(String userId) {
    // Note: Assuming a simple query where the user is either the student or mentor.
    // In a real app, you might need two queries or a compound array-contains query.
    return _firestore
        .collection('sessions')
        .where('studentId', isEqualTo: userId)
        .where('status', isEqualTo: 'upcoming')
        .orderBy('scheduledTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Session.fromFirestore(doc)).toList();
    });
  }

  Future<void> createSession(Session session) async {
    try {
      await _firestore
          .collection('sessions')
          .add(session.toMap())
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Network timeout. Please check your connection and try again.');
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }
}
