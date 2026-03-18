import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class GeminiChatService {
  Future<String> generatePreSessionBrief(String chatId) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return "Briefing unavailable: API key not set.";
    }

    GenerativeModel model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );

    // Fetch last 10 messages from Firestore directly for context
    String chatHistory = '';
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList()
          .reversed
          .toList();

      chatHistory = messages
          .map((m) => "User ${m.senderId}: ${m.content}")
          .join('\n');
    } catch (e) {
      return "Briefing unavailable: Could not fetch chat history.";
    }

    final prompt = '''
Analyze this chat. Summarize the technical issue the mentee needs help with in 2 concise sentences so the mentor can prepare.

Chat History:
$chatHistory

Brief:''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ??
          "No specific technical goal identified from chat history.";
    } catch (e) {
      if (e.toString().contains('flash') || e.toString().contains('not found')) {
        try {
          // Fallback to gemini-1.0-pro as it's the most widely supported legacy name
          model = GenerativeModel(model: 'gemini-1.0-pro', apiKey: apiKey);
          final response = await model.generateContent([Content.text(prompt)]);
          return response.text?.trim() ?? "Briefing summarized via legacy model.";
        } catch (e2) {
          return "AI Briefing failed (Flash & Pro): ${e2.toString()}";
        }
      }
      return "AI Briefing failed: ${e.toString()}";
    }
  }

  // Legacy method for backward compatibility if needed during transition
  Future<String> generateBrief(
    List<Message> recentMessages,
    String menteeId,
  ) async {
    return generatePreSessionBrief(recentMessages.first.chatId);
  }
}
