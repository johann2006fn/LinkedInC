import 'package:cloud_firestore/cloud_firestore.dart';

class MentorshipConnection {
  final String id;
  final String mentorId;
  final String studentId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final String mentorName;
  final String mentorSubtitle;
  final List<String> mentorTags;
  final String studentName;
  // Generic display name for whoever the current user is talking to
  final String otherUserName;
  final String otherUserId;

  MentorshipConnection({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.status,
    required this.createdAt,
    this.mentorName = '',
    this.mentorSubtitle = '',
    this.mentorTags = const [],
    this.studentName = '',
    this.otherUserName = '',
    this.otherUserId = '',
  });

  factory MentorshipConnection.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return MentorshipConnection(
      id: doc.id,
      mentorId: data['mentorId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mentorName: data['mentorName'] as String? ?? '',
      mentorSubtitle: data['mentorSubtitle'] as String? ?? '',
      mentorTags:
          (data['mentorTags'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      studentName: data['studentName'] as String? ?? '',
      otherUserName:
          data['otherUserName'] as String? ??
          data['mentorName'] as String? ??
          '',
      otherUserId:
          data['otherUserId'] as String? ?? data['mentorId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'studentId': studentId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'mentorName': mentorName,
      'mentorSubtitle': mentorSubtitle,
      'mentorTags': mentorTags,
    };
  }
}
