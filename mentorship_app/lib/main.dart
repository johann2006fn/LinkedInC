import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/antigravity_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(
    const ProviderScope(
      child: MentorshipApp(),
    ),
  );
}

class MentorshipApp extends ConsumerWidget {
  const MentorshipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MentorConnect',
      debugShowCheckedModeBanner: false,
      theme: AntigravityTheme.darkTheme,
      darkTheme: AntigravityTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: goRouter,
    );
  }
}
