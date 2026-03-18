import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/antigravity_theme.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const ProviderScope(child: MentorshipApp()));
}

class MentorshipApp extends ConsumerStatefulWidget {
  const MentorshipApp({super.key});

  @override
  ConsumerState<MentorshipApp> createState() => _MentorshipAppState();
}

class _MentorshipAppState extends ConsumerState<MentorshipApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updatePresence(true);
  }

  @override
  void dispose() {
    _updatePresence(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _updatePresence(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _updatePresence(false);
        break;
    }
  }

  Future<void> _updatePresence(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'isOnline': isOnline,
              'lastSeen': FieldValue.serverTimestamp(),
            });
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MentorHub',
      debugShowCheckedModeBanner: false,
      theme: AntigravityTheme.darkTheme,
      darkTheme: AntigravityTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: goRouter,
    );
  }
}
