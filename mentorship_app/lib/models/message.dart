import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentSize;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Message(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentName: data['attachmentName'] as String?,
      attachmentSize: data['attachmentSize'] as String?,
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
    };
  }
}
