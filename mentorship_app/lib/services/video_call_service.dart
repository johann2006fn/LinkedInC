import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'dart:developer' as developer;
import '../utils/video_call_utils.dart';

class VideoCallService {
  final _jitsiMeet = JitsiMeet();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> launchMeeting({
    required String chatId,
    required String userName,
    required String topic,
    String? callerId,
    Function()? onJoined,
    Function()? onTerminated,
    Map<String, dynamic>? configOverrides,
  }) async {
    try {
      final roomName = generateJitsiRoomId(chatId);
      developer.log('Launching Jitsi Meeting: $roomName on meet.jit.si');

      final options = JitsiMeetConferenceOptions(
        serverURL: "https://meet.jit.si",
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": true,
          "startWithVideoMuted": true,
          "subject": topic,
          "prejoinPageEnabled": false,
          "disableDeepLinking": true,
          "requireDisplayName": true,
          "buttonsWithConfirmation": ["hangup"],
          "enableClosePage": false,
          "disableThirdPartyRequests": true,
          "p2p": {"enabled": true},
          "doNotStoreRoom": true,
          "welcomePageEnabled": false,
          "disableInviteFunctions": true,
          // Prevent web redirect on mobile
          "disableModeratorIndicator": true,
          "enableInsecureRoomNameWarning": false,
          "enableNoisyMicDetection": true,
          ...?configOverrides,
        },
        featureFlags: {
          "unsecureRoomName.enabled": false,
          "welcomePageEnabled": false,
          "prejoinPageEnabled": false,
          "disableDeepLinking": true,
          "invite.enabled": false,
          "raise-hand.enabled": true,
          "recording.enabled": false,
          "calendar.enabled": false,
          "google-login.enabled": false,
          "apple-login.enabled": false,
          "facebook-login.enabled": false,
          "microsoft-login.enabled": false,
          "ios.screensharing.enabled": false,
          "android.screensharing.enabled": false,
          "help.enabled": false,
          "video-share.enabled": false,
          "kick-out.enabled": false,
          "conference-timer.enabled": true,
          "server-url-change.enabled": false,
          "meeting-password.enabled": false,
          "chat.enabled": true,
          "tile-view.enabled": true,
          "analytics.enabled": false,
          // Prevent Jitsi from opening browser
          "pip.enabled": true,
          "toolbox.alwaysVisible": false,
          "overflow-menu.enabled": true,
          "add-people.enabled": false,
          "close-captions.enabled": false,
          "live-streaming.enabled": false,
          "meeting-name.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(displayName: userName),
      );

      final callStartTime = DateTime.now();

      await _jitsiMeet.join(options, JitsiMeetEventListener(
        conferenceJoined: (url) {
          developer.log('Conference Joined: $url');
          onJoined?.call();

          // Log call start
          _logCallEvent(
            chatId: chatId,
            callerId: callerId ?? '',
            roomName: roomName,
            topic: topic,
            event: 'joined',
            callStartTime: callStartTime,
          );
        },
        conferenceTerminated: (url, error) {
          developer.log('Conference Terminated: $url, error: $error');

          // Log call end with duration
          final duration = DateTime.now().difference(callStartTime).inMinutes;
          _logCallEvent(
            chatId: chatId,
            callerId: callerId ?? '',
            roomName: roomName,
            topic: topic,
            event: 'terminated',
            callStartTime: callStartTime,
            durationMinutes: duration,
          );

          onTerminated?.call();
        },
      ));
    } catch (e) {
      developer.log('Error launching Jitsi Meeting: $e', error: e);
      rethrow;
    }
  }

  /// Logs a call event to Firestore for call history / analytics
  Future<void> _logCallEvent({
    required String chatId,
    required String callerId,
    required String roomName,
    required String topic,
    required String event,
    required DateTime callStartTime,
    int? durationMinutes,
  }) async {
    try {
      await _firestore.collection('call_logs').add({
        'chatId': chatId,
        'callerId': callerId,
        'roomName': roomName,
        'topic': topic,
        'event': event,
        'callStartTime': Timestamp.fromDate(callStartTime),
        'timestamp': FieldValue.serverTimestamp(),
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      });
    } catch (e) {
      developer.log('Failed to log call event: $e');
    }
  }

  // Maintaining compatibility for existing calls if any
  Future<void> launchJitsiMeeting(String chatId, String userName) async {
    return launchMeeting(
      chatId: chatId,
      userName: userName,
      topic: "Mentorship Session",
    );
  }
}
