import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, sessionProposal, system }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentSize;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final String? mentorId;
  final String? menteeId;
  final String? menteeName;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.type = MessageType.text,
    this.metadata,
    this.mentorId,
    this.menteeId,
    this.menteeName,
  });

  // Metadata helpers
  DateTime? get proposedTime => metadata?['proposedTime'] != null
      ? (metadata!['proposedTime'] as Timestamp).toDate()
      : null;
  String? get sessionTopic => metadata?['sessionTopic'] as String?;
  String? get aiBrief => metadata?['aiBrief'] as String?;
  String? get sessionStatus =>
      metadata?['sessionStatus']
          as String?; // 'proposed', 'rescheduled', 'confirmed', 'completed'

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // Handle string to enum conversion for backward compatibility
    MessageType messageType = MessageType.text;
    final typeStr = data['type'] as String? ?? 'text';
    if (typeStr == 'session_proposal' || typeStr == 'sessionProposal') {
      messageType = MessageType.sessionProposal;
    } else if (typeStr == 'system') {
      messageType = MessageType.system;
    }

    return Message(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentName: data['attachmentName'] as String?,
      attachmentSize: data['attachmentSize'] as String?,
      type: messageType,
      metadata: data['metadata'] as Map<String, dynamic>?,
      mentorId: data['mentorId'] as String?,
      menteeId: data['menteeId'] as String?,
      menteeName: data['menteeName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'attachmentSize': attachmentSize,
      'type': type.name,
      'metadata': metadata,
      'mentorId': mentorId,
      'menteeId': menteeId,
      'menteeName': menteeName,
    };
  }
}
