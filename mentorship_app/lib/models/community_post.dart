import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final int likesCount;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CommunityPost(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Mentor',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
    };
  }
}
