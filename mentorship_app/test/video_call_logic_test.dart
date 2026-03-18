import 'package:test/test.dart';
import 'package:mentorship_app/utils/video_call_utils.dart';

void main() {
  // ─── Room ID Generation ─────────────────────────────────────────────────────

  group('generateJitsiRoomId', () {
    test('prefixes a clean chatId with "mentorhub-"', () {
      expect(generateJitsiRoomId('chat123'), equals('mentorhub-chat123'));
    });

    test('strips special characters before prefixing', () {
      expect(generateJitsiRoomId('chat_123!@#'), equals('mentorhub-chat123'));
    });

    test('handles an empty string gracefully', () {
      expect(generateJitsiRoomId(''), equals('mentorhub-'));
    });

    test('strips spaces and hyphens', () {
      expect(
        generateJitsiRoomId('my chat-room 42'),
        equals('mentorhub-mychatroom42'),
      );
    });
  });

  // ─── Temporal Window Logic ──────────────────────────────────────────────────

  group('isJoinWindowOpen', () {
    // Session starts at a fixed reference time
    final sessionStart = DateTime(2026, 3, 14, 14, 0); // 2:00 PM

    test('returns true exactly 5 minutes before session starts', () {
      final fiveMinBefore = sessionStart.subtract(const Duration(minutes: 5));
      expect(
        isJoinWindowOpen(
          sessionStart: sessionStart,
          currentTime: fiveMinBefore,
        ),
        isTrue,
      );
    });

    test('returns true during the session (10 min after start)', () {
      final tenMinAfter = sessionStart.add(const Duration(minutes: 10));
      expect(
        isJoinWindowOpen(sessionStart: sessionStart, currentTime: tenMinAfter),
        isTrue,
      );
    });

    test('returns false 6 minutes before session starts (too early)', () {
      final sixMinBefore = sessionStart.subtract(const Duration(minutes: 6));
      expect(
        isJoinWindowOpen(sessionStart: sessionStart, currentTime: sixMinBefore),
        isFalse,
      );
    });

    test('returns false 61 minutes after session starts (too late)', () {
      final sixtyOneMinAfter = sessionStart.add(const Duration(minutes: 61));
      expect(
        isJoinWindowOpen(
          sessionStart: sessionStart,
          currentTime: sixtyOneMinAfter,
        ),
        isFalse,
      );
    });

    test('returns true exactly at session start time', () {
      expect(
        isJoinWindowOpen(sessionStart: sessionStart, currentTime: sessionStart),
        isTrue,
      );
    });

    test('returns true exactly 60 minutes after start (boundary)', () {
      final exactEnd = sessionStart.add(const Duration(minutes: 60));
      expect(
        isJoinWindowOpen(sessionStart: sessionStart, currentTime: exactEnd),
        isTrue,
      );
    });
  });
}
