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
      final chats = snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
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
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  Future<void> sendMessage(String chatId, Message message) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    
    try {
      await _firestore.runTransaction((transaction) async {
        final messagesRef = chatRef.collection('messages').doc();
        transaction.set(messagesRef, message.toMap());
        transaction.update(chatRef, {
          'lastMessage': message.content,
          'lastUpdated': message.timestamp,
        });
      }).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Network timeout. Please check your connection and try again.');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
