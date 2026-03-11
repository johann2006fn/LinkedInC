import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../theme/antigravity_theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String currentUserId;
  final String currentUserName;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
  }

  Future<void> _enableScreenProtection() async {
    await ScreenProtector.preventScreenshotOn();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy Notice: This call is protected against screenshots and recording.'),
          backgroundColor: AntigravityTheme.electricPurple,
        ),
      );
    }
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AntigravityTheme.pureBlack,
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: 1799505657, 
          appSign: '7029a746e74217a4617b572621997b0f4bc83677f4993dec416147006841d8e5', 
          userID: widget.currentUserId,
          userName: widget.currentUserName,
          callID: widget.callId,
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        ),
      ),
    );
  }
}
