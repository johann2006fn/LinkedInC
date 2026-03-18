import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/mentor_match.dart';

class GeminiMatchService {
  Future<List<MentorMatch>> getMatches(
    AppUser mentee,
    List<AppUser> mentors,
  ) async {
    if (mentors.isEmpty) return [];

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not defined in .env file');
    }

    // Forced stable configuration - exactly 'gemini-2.0-flash'
    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

    final menteeJson = mentee.toMatchingDescription();
    final mentorsJsonList = mentors
        .map((m) => 'ID: ${m.id}\n${m.toMatchingDescription()}')
        .join('\n\n---\n\n');

    final prompt =
        '''
You are an expert AI matchmaking algorithm.
Compare this Mentee against the following list of Mentors.
Calculate a match percentage (0-100) based on how well their skills, goals, and bios align.

Mentee Profile:
$menteeJson

Available Mentors:
$mentorsJsonList

Instructions:
1. Return ONLY a valid JSON array of objects.
2. CRITICAL: You MUST return every single mentor provided in the input array. Do not filter anyone out.
3. If a mentor has zero matching skills, give them a score between 10-30 and a generic reason like 'Explore a new domain'.
4. Return the exact following keys for each object:
- "mentorId": (string) the ID of the matched mentor
- "score": (integer) match percentage from 0 to 100
- "reason": (string) a concise sentence explaining why they are a good match

Example Output:
[
  {
    "mentorId": "123",
    "score": 95,
    "reason": "Both share a strong interest in UI/UX and Flutter development."
  }
]
''';

    try {
      if (kDebugMode) {
        print(
          '🤖 SENDING TO GEMINI: Mentee tags: ${mentee.tags}, Mentor count: ${mentors.length}',
        );
      }

      final response = await model.generateContent([Content.text(prompt)]);

      if (kDebugMode) {
        print('🤖 RAW GEMINI RESPONSE: ${response.text}');
      }

      String rawJson = response.text ?? '[]';

      // Bulletproof JSON Parsing (Sub-string Extraction)
      rawJson = rawJson.trim();
      final startIndex = rawJson.indexOf('[');
      final endIndex = rawJson.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        rawJson = rawJson.substring(startIndex, endIndex + 1);
      }

      List<dynamic> jsonList = [];
      try {
        jsonList = jsonDecode(rawJson);
      } catch (e) {
        if (kDebugMode) {
          print('🔴 JSON PARSE ERROR: $e');
        }
        // Fallback inside JSON parse error
        return mentors
            .map(
              (m) => MentorMatch(
                mentor: m,
                score: 50,
                reason: 'Previewing mentor profile (AI sync in progress).',
              ),
            )
            .toList();
      }

      // Create a map of mentors by ID for fast lookup
      final mentorMap = {for (var m in mentors) m.id: m};

      final List<MentorMatch> matches = [];

      for (var item in jsonList) {
        final id = item['mentorId']?.toString();
        final score = item['score'] is num
            ? (item['score'] as num).toInt()
            : null;
        final reason = item['reason']?.toString();

        if (id != null &&
            score != null &&
            reason != null &&
            mentorMap.containsKey(id)) {
            
          // STAMP FIRTOSTORE IMMEDIATELY
          try {
            await FirebaseFirestore.instance.collection('users').doc(id).update({
              'matchReason': reason,
              'matchScore': score,
            });
          } catch (e) {
            print('Gemini API Error (Firestore Update Failed): $e');
          }

          matches.add(
            MentorMatch(mentor: mentorMap[id]!, score: score, reason: reason),
          );
        }
      }

      // Sort by descending score
      matches.sort((a, b) => b.score.compareTo(a.score));

      return matches;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Gemini Match Fatal Error: $e');
        print('🔄 FALLBACK: Returning all mentors with neutral scores.');
      }
      // CRITICAL: Empty Result Protection - Return all mentors with score 50
      // if the AI call fails (e.g., 404, rate limit, etc.)
      return mentors
          .map(
            (m) => MentorMatch(
              mentor: m,
              score: 50,
              reason: 'Previewing mentor profile (AI service pending sync).',
            ),
          )
          .toList();
    }
  }
}
