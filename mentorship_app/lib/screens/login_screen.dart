import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Check if profile exists
      final profileExists = await authService.userProfileExists(user.uid);
      if (!mounted) return;

      if (profileExists) {
        // Existing user — check role and route accordingly
        final profile = await authService.getCurrentUserProfile();
        if (!mounted) return;
        if (profile?.role == 'mentor') {
          context.go('/mentor');
        } else {
          context.go('/');
        }
      } else {
        // New user — go to registration to set role & college code
        context.go('/register');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Logo/Icon area
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                // App name
                const Text(
                  'MentorConnect',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your college mentorship network.\nFor students. By students.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.65),
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 2),
                // Access notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: Color(0xFF4ADE80), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This app is exclusively for verified college students. A valid college code is required to register.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Google Sign-in button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                width: 24,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.g_mobiledata,
                                    size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const Spacer(),
                Text(
                  '© 2026 MentorConnect • College Use Only',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
