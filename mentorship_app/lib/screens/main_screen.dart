import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class MainScreen extends ConsumerWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isMentor =
        userAsync.whenOrNull(data: (u) => u?.role == 'mentor') ?? false;
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      extendBody: true,
      body: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: CustomBottomNavBar(
                currentIndex: _calculateIndex(location, isMentor),
                isMentor: isMentor,
                onTap: (i) => _onTap(i, context, isMentor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Index calculator ─────────────────────────────────────
  static int _calculateIndex(String location, bool isMentor) {
    if (isMentor) {
      // Mentor: 0=Dashboard, 1=Chat, 2=Calendar, 3=Profile
      if (location == '/mentor') return 0;
      if (location.startsWith('/chat')) return 1;
      if (location == '/calendar') return 2;
      if (location.startsWith('/profile')) return 3;
      return 0;
    } else {
      // Mentee: 0=Explore, 1=Chat, 2=Network, 3=Profile
      if (location == '/') return 0;
      if (location.startsWith('/chat')) return 1;
      if (location.startsWith('/network') ||
          location.startsWith('/mentee-network')) {
        return 2;
      }
      if (location.startsWith('/profile')) return 3;
      return 0;
    }
  }

  // ── Tap handler ──────────────────────────────────────────
  void _onTap(int index, BuildContext context, bool isMentor) {
    if (isMentor) {
      switch (index) {
        case 0:
          context.go('/mentor');
          break;
        case 1:
          context.go('/chat');
          break;
        case 2:
          context.go('/calendar');
          break;
        case 3:
          context.go('/profile');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/chat');
          break;
        case 2:
          context.go('/network');
          break;
        case 3:
          context.go('/profile');
          break;
      }
    }
  }
}
