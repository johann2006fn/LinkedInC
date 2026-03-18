import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReview({
    required List<String> selectedEndorsements,
    required String comment,
    required String mentorId,
    required String menteeId,
    required String chatId,
    required String messageId,
  }) async {
    final mentorRef = _firestore.collection('users').doc(mentorId);
    final feedbackRef = mentorRef.collection('private_feedback').doc();
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    return _firestore.runTransaction((transaction) async {
      // 1. Get current mentor data
      final mentorSnapshot = await transaction.get(mentorRef);
      if (!mentorSnapshot.exists) {
        throw Exception("Mentor does not exist");
      }

      final data = mentorSnapshot.data() ?? {};
      final int currentSessions = data['sessionsCompleted'] as int? ?? 0;
      final Map<String, int> currentEndorsements = Map<String, int>.from(
        data['endorsements'] ?? {},
      );

      // 2. Update endorsements count
      for (final tag in selectedEndorsements) {
        currentEndorsements[tag] = (currentEndorsements[tag] ?? 0) + 1;
      }

      // 3. Update mentor document
      transaction.update(mentorRef, {
        'sessionsCompleted': currentSessions + 1,
        'endorsements': currentEndorsements,
      });

      // 4. Save private feedback if present
      if (comment.isNotEmpty) {
        transaction.set(feedbackRef, {
          'menteeId': menteeId,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
          'messageId': messageId,
        });
      }

      // 5. Update session message status
      transaction.update(messageRef, {
        'status': 'completed',
        'metadata.sessionStatus': 'completed',
      });
    });
  }
}
