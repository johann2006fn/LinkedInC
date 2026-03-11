import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/video_call_screen.dart';
import '../screens/profile_screen.dart';
import '../models/chat.dart';
import '../screens/main_screen.dart';
import '../screens/login_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/mentor_dashboard_screen.dart';
import '../screens/mentor_calendar_screen.dart';
import '../screens/mentee_network_screen.dart';
import '../screens/mentor_detail_screen.dart';
import '../screens/match_screen.dart';
import '../screens/community_screen.dart';
import '../screens/search_mentors_screen.dart';
// Onboarding
import '../screens/welcome_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/mentee_onboarding_screen.dart';
import '../screens/mentor_onboarding_screen.dart';
import '../screens/preferences_screen.dart';
import '../models/app_user.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/welcome',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.uri.path;
    final publicRoutes = ['/welcome', '/auth', '/login', '/register'];

    if (user == null) {
      return publicRoutes.contains(location) ? null : '/welcome';
    }
    if (location == '/welcome' || location == '/auth' || location == '/login') {
      return '/splash';
    }
    return null;
  },
  routes: [
    // ── Onboarding ─────────────────────────────────────────
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(path: '/role-selection', builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(path: '/onboarding/mentee', builder: (_, __) => const MenteeOnboardingScreen()),
    GoRoute(path: '/onboarding/mentor', builder: (_, __) => const MentorOnboardingScreen()),
    GoRoute(path: '/onboarding/preferences', builder: (_, __) => const PreferencesScreen()),

    // ── Legacy ─────────────────────────────────────────────
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegistrationScreen()),

    // ── Splash / Role Check ────────────────────────────────
    GoRoute(path: '/splash', builder: (_, __) => const RoleSplashScreen()),

    // ── AI Matching ────────────────────────────────────────
    GoRoute(path: '/mentor/run-matching', builder: (_, __) => const MatchScreenScreen()),

    // ── Mentor Detail (outside shell so no nav bar) ────────
    GoRoute(
      path: '/mentor-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final mentor = state.extra as AppUser;
        return MentorDetailScreen(mentor: mentor);
      },
    ),

    // ── Search Mentors ─────────────────────────────────────
    GoRoute(
      path: '/search-mentors',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchMentorsScreen(),
    ),

    // ── Chat Detail (outside shell) ────────────────────────
    GoRoute(
      path: '/chat/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final chat = state.extra as Chat;
        return ChatDetailScreen(chat: chat);
      },
    ),

    // ── Video Call (outside shell) ────────────────────────
    GoRoute(
      path: '/video-call',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final query = state.uri.queryParameters;
        return VideoCallScreen(
          callId: query['callId'] ?? 'demo_call',
          currentUserId: query['currentUserId'] ?? '',
          currentUserName: query['currentUserName'] ?? 'User',
        );
      },
    ),

    // ── Main Shell ─────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        // Mentee tabs
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/chat', builder: (_, __) => const ChatListScreen()),
        GoRoute(path: '/network', builder: (_, __) => const MenteeNetworkScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

        // Mentor tabs
        GoRoute(path: '/mentor', builder: (_, __) => const MentorDashboardScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const MentorCalendarScreen()),

        // Kept for legacy / community
        GoRoute(path: '/community', builder: (_, __) => const CommunityScreen()),
        GoRoute(path: '/mentee-network', builder: (_, __) => const MenteeNetworkScreen()),
      ],
    ),
  ],
);

// ── Role Splash (role-checker) ─────────────────────────────
class RoleSplashScreen extends StatefulWidget {
  const RoleSplashScreen({super.key});

  @override
  State<RoleSplashScreen> createState() => _RoleSplashScreenState();
}

class _RoleSplashScreenState extends State<RoleSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndRedirect();
  }

  Future<void> _checkAndRedirect() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/welcome');
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    if (!doc.exists) {
      context.go('/role-selection');
      return;
    }

    final data = doc.data()!;
    final role = data['role'] ?? 'student';
    final isProfileComplete = data['isProfileComplete'] ?? false;

    if (!isProfileComplete) {
      context.go(role == 'mentor' ? '/onboarding/mentor' : '/onboarding/mentee');
      return;
    }

    context.go(role == 'mentor' ? '/mentor' : '/');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0B14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            SizedBox(height: 20),
            Text('Loading your profile…',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
