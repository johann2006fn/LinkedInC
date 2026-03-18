// ignore_for_file: unnecessary_underscores
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../models/chat.dart';
import '../screens/main_screen.dart';
import '../screens/login_screen.dart';
import '../screens/mentor_dashboard_screen.dart';
import '../screens/mentor_calendar_screen.dart';
import '../screens/mentee_network_screen.dart';
import '../screens/mentor_detail_screen.dart';
import '../screens/match_screen.dart';
import '../screens/community_screen.dart';
import '../screens/search_mentors_screen.dart';
// Onboarding
import '../services/auth_service.dart';
import '../screens/welcome_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/identity_verification_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/mentee_onboarding_screen.dart';
import '../screens/mentor_onboarding_screen.dart';
import '../screens/preferences_screen.dart';
import '../models/app_user.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

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

    // Protected logic for logged-in users
    final publicRoutePaths = ['/welcome', '/auth', '/login', '/register'];

    // If logged in and on a public route, check role/onboarding via splash
    if (publicRoutePaths.contains(location)) {
      return '/splash';
    }

    return null;
  },
  routes: [
    // ── Onboarding ─────────────────────────────────────────
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(
      path: '/verify',
      builder: (_, __) => const IdentityVerificationScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (_, __) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/onboarding/mentee',
      builder: (_, __) => const MenteeOnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/mentor',
      builder: (_, __) => const MentorOnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/preferences',
      builder: (_, __) => const PreferencesScreen(),
    ),

    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // ── Splash / Role Check ────────────────────────────────
    GoRoute(path: '/splash', builder: (_, __) => const RoleSplashScreen()),

    // ── AI Matching ────────────────────────────────────────
    GoRoute(
      path: '/mentor/run-matching',
      builder: (_, __) => const MatchScreen(),
    ),

    // ── Mentor Detail (outside shell so no nav bar) ────────
    GoRoute(
      path: '/mentor-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return MentorDetailScreen(
            mentor: data['mentor'] as AppUser,
            matchScore: data['matchScore'] as double?,
            matchReason: data['matchReason'] as String?,
          );
        }
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

    // ── Shell ──────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        // Mentee tabs
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/chat',
          builder: (_, __) => const ChatListScreen(),
          routes: [
            GoRoute(
              path: ':chatId',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final chatId = state.pathParameters['chatId']!;
                if (state.extra is Chat) {
                  return ChatDetailScreen(chat: state.extra as Chat);
                }
                // Fallback: If no Chat object in extra, we'll need to fetch it in the screen.
                // For now, I'll pass a "shell" Chat object and let the screen handle the ID.
                return ChatDetailScreen(
                  chat: Chat(
                    id: chatId,
                    participantIds: [],
                    lastMessage: '',
                    lastUpdated: DateTime.now(),
                    otherUserName: 'Chat',
                  ),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/network',
          builder: (_, __) => const MenteeNetworkScreen(),
        ),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

        // Mentor tabs
        GoRoute(
          path: '/mentor',
          builder: (_, __) => const MentorDashboardScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (_, __) => const MentorCalendarScreen(),
        ),

        // Kept for legacy / community
        GoRoute(
          path: '/community',
          builder: (_, __) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/mentee-network',
          builder: (_, __) => const MenteeNetworkScreen(),
        ),
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAndRedirect();
  }

  Future<void> _checkAndRedirect() async {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    debugPrint('DEBUG: [RoleSplashScreen] Starting _checkAndRedirect');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('DEBUG: [RoleSplashScreen] No user found, going to /welcome');
      if (mounted) context.go('/welcome');
      return;
    }

    debugPrint('DEBUG: [RoleSplashScreen] Fetching user doc for ${user.uid}');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (!doc.exists) {
        debugPrint(
          'DEBUG: [RoleSplashScreen] User doc does not exist, going to /verify',
        );
        context.go('/verify');
        return;
      }

      final data = doc.data()!;
      final isVerified = data['isVerifiedCollegeUser'] ?? false;
      final role = data['role'] ?? 'student';
      final isProfileComplete = data['isProfileComplete'] ?? false;

      debugPrint(
        'DEBUG: [RoleSplashScreen] Role: $role, Verified: $isVerified, ProfileComplete: $isProfileComplete',
      );

      if (!isVerified) {
        debugPrint('DEBUG: [RoleSplashScreen] Not verified, going to /verify');
        context.go('/verify');
        return;
      }

      if (!isProfileComplete) {
        final target = role == 'mentor'
            ? '/onboarding/mentor'
            : '/onboarding/mentee';
        debugPrint(
          'DEBUG: [RoleSplashScreen] Profile incomplete, going to $target',
        );
        context.go(target);
        return;
      }

      final dashboard = role == 'mentor' ? '/mentor' : '/';
      debugPrint('DEBUG: [RoleSplashScreen] Go to dashboard: $dashboard');
      context.go(dashboard);
    } catch (e) {
      debugPrint('DEBUG: [RoleSplashScreen] Error in _checkAndRedirect: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage == null) ...[
                const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                const SizedBox(height: 24),
                const Text(
                  'Loading your profile…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verifying access and connection',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Connection Timeout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We had trouble reaching the server. Please check your internet and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _checkAndRedirect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => AuthService().signOut(),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
