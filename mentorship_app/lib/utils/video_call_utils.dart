/// Pure Dart utility functions for video call logic.
/// No Firebase, Jitsi, or Flutter dependencies — fully testable.
library;

/// Generates a sanitized Jitsi room ID from a chat ID.
///
/// Strips all non-alphanumeric characters and prepends the "mentorhub-" prefix.
/// Example: `generateJitsiRoomId("chat_123!@#")` → `"mentorhub-chat123"`
String generateJitsiRoomId(String chatId) {
  final sanitized = chatId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  return 'mentorhub-$sanitized';
}

/// Checks whether the temporal join window is currently open for a session.
///
/// The window opens **5 minutes before** [sessionStart] and closes
/// **60 minutes after** [sessionStart].
///
/// [currentTime] is injectable for testing (defaults to `DateTime.now()`).
bool isJoinWindowOpen({required DateTime sessionStart, DateTime? currentTime}) {
  final now = currentTime ?? DateTime.now();
  final windowOpens = sessionStart.subtract(const Duration(minutes: 5));
  final windowCloses = sessionStart.add(const Duration(minutes: 60));
  return !now.isBefore(windowOpens) && !now.isAfter(windowCloses);
}
