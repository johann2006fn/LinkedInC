import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  final String id;
  final String mentorId;
  final String studentId;
  final String chatId;
  final String topic;
  final DateTime scheduledTime;
  final String status; // 'upcoming', 'completed', 'canceled'
  final String mentorName;
  final String studentName;
  final Map<String, bool> presence; // userId: isInCall

  Session({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.chatId,
    required this.topic,
    required this.scheduledTime,
    required this.status,
    this.mentorName = '',
    this.studentName = '',
    this.presence = const {},
  });

  factory Session.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Session(
      id: doc.id,
      mentorId: data['mentorId'] ?? '',
      studentId: data['studentId'] ?? '',
      chatId: data['chatId'] ?? '',
      topic: data['topic'] ?? 'Mentorship Session',
      scheduledTime:
          (data['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'upcoming',
      mentorName: data['mentorName'] ?? '',
      studentName: data['studentName'] ?? '',
      presence: Map<String, bool>.from(data['presence'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'studentId': studentId,
      'chatId': chatId,
      'topic': topic,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'status': status,
      'mentorName': mentorName,
      'studentName': studentName,
      'presence': presence,
    };
  }
}
