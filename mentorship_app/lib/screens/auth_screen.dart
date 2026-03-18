import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/antigravity_theme.dart';
import '../services/auth_service.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  // ── Google Sign In ───────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return; // Prevent double-tap
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      debugPrint('DEBUG: [Google Sign-In] Successful');
      if (user != null && mounted) {
        // Refresh the user provider to ensure the router has the latest state
        ref.invalidate(currentUserProvider);
        context.go('/splash');
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: Failed at [Google Sign-In] - $e');
      _showCrashReport(e, stackTrace, 'Google Sign-In');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0B14),
        body: Stack(
          children: [
            // ── Purple glow top-right ────────────────────────
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AntigravityTheme.electricPurple.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => context.go('/welcome'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1527),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Headline
                    const Text(
                      'Join the\nNetwork.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Connect with mentors from your college',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                    const SizedBox(height: 40),

                    // ── Social Buttons ───────────────────────
                    _socialButton(
                      icon: FontAwesomeIcons.google,
                      label: 'Continue with Google',
                      onTap: _isLoading ? null : _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1527),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCrashReport(dynamic e, StackTrace stackTrace, String location) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1527),
        title: const Text(
          '🔥 Crash Report',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Failed at: $location\n\nError:\n${e.toString()}\n\nStack Trace:\n$stackTrace',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
