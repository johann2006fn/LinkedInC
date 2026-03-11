import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastUpdated;
  final String otherUserName;

  Chat({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastUpdated,
    this.otherUserName = '',
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Chat(
      id: doc.id,
      participantIds: (data['participantIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      lastMessage: data['lastMessage'] as String? ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      otherUserName: data['otherUserName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'otherUserName': otherUserName,
    };
  }
}
