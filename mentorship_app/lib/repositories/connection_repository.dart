import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection.dart';
import '../models/app_notification.dart';

class ConnectionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MentorshipConnection>> getPendingRequests(String userId) {
    return _firestore
        .collection('connections')
        .where('mentorId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MentorshipConnection.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<MentorshipConnection>> getActiveMentors(String userId) {
    return _firestore
        .collection('connections')
        .where('studentId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MentorshipConnection.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> requestMentorship(MentorshipConnection connection) async {
    try {
      await _firestore
          .collection('connections')
          .add(connection.toMap())
          .timeout(const Duration(seconds: 10));

      // Log for the Mentee
      await logActivity(
        userId: connection.studentId,
        title: 'Request Sent',
        message: 'You requested mentorship from ${connection.mentorName}.',
        type: 'request_sent',
      );

      // Log for the Mentor
      await logActivity(
        userId: connection.mentorId,
        title: 'New Request',
        message: '${connection.studentName} wants to connect with you!',
        type: 'request_received',
      );
    } on TimeoutException {
      throw Exception(
        'Network timeout. Please check your connection and try again.',
      );
    } catch (e) {
      throw Exception('Failed to request mentorship: $e');
    }
  }

  Future<void> logActivity({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      final notification = AppNotification(
        id: docRef.id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
      );
      await docRef.set(notification.toMap());
    } catch (e) {
      debugPrint('Failed to log activity: $e');
    }
  }

  Future<void> updateConnectionStatus(
    String connectionId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('connections')
          .doc(connectionId)
          .update({'status': status})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception(
        'Network timeout. Please check your connection and try again.',
      );
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

  Future<void> acceptMentorshipRequest(
    String connectionId,
    String studentId,
    String mentorId,
    String mentorName,
  ) async {
    final batch = _firestore.batch();

    // 1. Update connection status
    final connectionRef = _firestore
        .collection('connections')
        .doc(connectionId);
    batch.update(connectionRef, {'status': 'accepted'});

    // 2. Create chat document
    // We use a stable ID for the chat to prevent duplicates
    final chatId = studentId.hashCode <= mentorId.hashCode
        ? '${studentId}_$mentorId'
        : '${mentorId}_$studentId';

    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.set(chatRef, {
      'participantIds': [studentId, mentorId],
      'lastMessage':
          'You are now connected! Start your mentorship journey here.',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // 3. Add system message to the chat
    final msgRef = chatRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': 'system',
      'content': 'You are now connected! Start your mentorship journey here.',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    // 4. Create notification for student
    final notificationRef = _firestore.collection('notifications').doc();
    batch.set(notificationRef, {
      'userId': studentId,
      'title': 'Request Accepted',
      'message': 'Your request to $mentorName was accepted!',
      'type': 'request_accepted',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }
}
