import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection.dart';

class ConnectionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MentorshipConnection>> getPendingRequests(String userId) {
    return _firestore
        .collection('connections')
        .where('mentorId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MentorshipConnection.fromFirestore(doc)).toList();
    });
  }

  Stream<List<MentorshipConnection>> getActiveMentors(String userId) {
    return _firestore
        .collection('connections')
        .where('studentId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MentorshipConnection.fromFirestore(doc)).toList();
    });
  }

  Future<void> requestMentorship(MentorshipConnection connection) async {
    try {
      await _firestore
          .collection('connections')
          .add(connection.toMap())
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Network timeout. Please check your connection and try again.');
    } catch (e) {
      throw Exception('Failed to request mentorship: $e');
    }
  }
  
  Future<void> updateConnectionStatus(String connectionId, String status) async {
    try {
      await _firestore
          .collection('connections')
          .doc(connectionId)
          .update({'status': status})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Network timeout. Please check your connection and try again.');
    } catch (e) {
      throw Exception('Failed to update connection status: $e');
    }
  }

  Future<bool> hasPendingConnection(String studentId, String mentorId) async {
    try {
      final query = await _firestore
          .collection('connections')
          .where('studentId', isEqualTo: studentId)
          .where('mentorId', isEqualTo: mentorId)
          .where('status', isEqualTo: 'pending')
          .get()
          .timeout(const Duration(seconds: 10));
          
      return query.docs.isNotEmpty;
    } catch (_) {
      // In case of error (e.g. offline layout), assume false to allow attempting
      return false;
    }
  }
}
