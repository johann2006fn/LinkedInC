import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => Chat.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid needing a composite Firestore index
          chats.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
          return chats;
        });
  }

  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> sendMessage(String chatId, Message message) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    try {
      await _firestore
          .runTransaction((transaction) async {
            final messagesRef = chatRef.collection('messages').doc();
            transaction.set(messagesRef, message.toMap());
            transaction.update(chatRef, {
              'lastMessage': message.content,
              'lastUpdated': message.timestamp,
            });
          })
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception(
        'Network timeout. Please check your connection and try again.',
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> clearChat(String chatId) async {
    final messagesRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');
    
    final snapshots = await messagesRef.get();
    final batch = _firestore.batch();
    
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    // Update last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': 'Chat cleared',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Message>> getConfirmedSessionsForMentor(String mentorId) {
    return _firestore
        .collectionGroup('messages')
        .where('type', isEqualTo: MessageType.sessionProposal.name)
        .where('mentorId', isEqualTo: mentorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .where((msg) => msg.sessionStatus == 'confirmed')
              .toList();
        });
  }

  Future<String> getOrCreateChatId(String userId1, String userId2) async {
    // Deterministic sorted ID generation
    final ids = [userId1, userId2]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final chatRef = _firestore.collection('chats').doc(chatId);
    final doc = await chatRef.get();

    if (!doc.exists) {
      // Use a transaction or batch if needed, but set() is safe for a single doc
      await chatRef.set({
        'participantIds': ids,
        'lastMessage':
            'You are now connected! Start your mentorship journey here.',
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add initial system message
      await chatRef.collection('messages').add({
        'senderId': 'system',
        'content': 'You are now connected! Start your mentorship journey here.',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });
    }

    return chatId;
  }
}
