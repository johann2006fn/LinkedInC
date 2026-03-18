import 'package:cloud_firestore/cloud_firestore.dart';

class MentorshipSession {
  final String id;
  final String mentorId;
  final String menteeId;
  final DateTime startTime;
  final DateTime endTime;
  final String jitsiRoomName;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? agenda;

  MentorshipSession({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.startTime,
    required this.endTime,
    required this.jitsiRoomName,
    required this.status,
    this.agenda,
  });

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'menteeId': menteeId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'jitsiRoomName': jitsiRoomName,
      'status': status,
      'agenda': agenda,
    };
  }

  factory MentorshipSession.fromMap(String id, Map<String, dynamic> map) {
    return MentorshipSession(
      id: id,
      mentorId: map['mentorId'] ?? '',
      menteeId: map['menteeId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      jitsiRoomName: map['jitsiRoomName'] ?? '',
      status: map['status'] ?? 'pending',
      agenda: map['agenda'],
    );
  }
}
