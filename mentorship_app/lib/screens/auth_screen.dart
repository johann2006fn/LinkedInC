import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/antigravity_theme.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _uniCodeController = TextEditingController();
  bool _isLoading = false;
  bool _showUniGate = false; // shown after social login success

  @override
  void dispose() {
    _uniCodeController.dispose();
    super.dispose();
  }

  // ── Google Sign In ───────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return; // Prevent double-tap
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _authService.signInWithGoogle();
      print('DEBUG: [Google Sign-In] Successful');
      if (user != null && mounted) {
        final hasProfile = await _authService.userProfileExists(user.uid);
        print('DEBUG: [Check User Profile Exists] Successful');
        if (hasProfile) {
          context.go('/splash'); 
        } else {
          setState(() => _showUniGate = true); // show uni gate for NEW users
        }
      }
    } catch (e, stackTrace) {
      print('ERROR: Failed at [Google Sign-In] - $e');
      _showCrashReport(e, stackTrace, 'Google Sign-In');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── University Code validation ───────────────────────────
  Future<void> _validateAndProceed() async {
    if (_isLoading) return; // Prevent double-tap
    final code = _uniCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showError('Please enter your university code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Verify code against Firestore
      final isValid = await _authService.verifyCollegeCode(code).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Network timeout: Could not verify college code. Please check your connection.');
    });
      print('DEBUG: [Verify College Code] Successful');
      if (!isValid) {
        if (mounted) _showError('Invalid university code. Please contact your campus admin.');
        return;
      }

      // 2. Clear overlay
      if (mounted) setState(() => _showUniGate = false);

      // 3. Handle Flow
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        throw Exception("Session expired or currentUser is null during University Code validation.");
      }
      print('DEBUG: [Get Current User] Successful');

      // Given they just verified code and don't have a profile
      if (mounted) {
        context.go('/role-selection');
      }
    } catch (e, stackTrace) {
      print('ERROR: Failed at [University Code Validation] - $e');
      _showCrashReport(e, stackTrace, 'University Code Validation');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
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
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Headline
                  const Text('Join the\nNetwork.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        height: 1.15,
                      )),
                  const SizedBox(height: 6),
                  const Text('Connect with mentors from your college',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
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

          // ── University Code Overlay Gate ─────────────────
          if (_showUniGate)
            _buildUniCodeOverlay(),
        ],
      ),
      ),
    );
  }

  Widget _buildUniCodeOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showUniGate = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismissal on card tap
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1527),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color:
                        AntigravityTheme.electricPurple.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AntigravityTheme.electricPurple.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AntigravityTheme.electricPurple
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: AntigravityTheme.electricPurple, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verify Your College',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'Outfit')),
                            Text('Enter your university access code',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Code Input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2040),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AntigravityTheme.electricPurple
                              .withValues(alpha: 0.3)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _uniCodeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AntigravityTheme.electricPurple,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4),
                      decoration: const InputDecoration(
                        hintText: 'UVCE01',
                        hintStyle: TextStyle(
                            color: Colors.white24, fontSize: 18, letterSpacing: 4),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('e.g. UVCE01, BIT22, MIT99',
                      style: TextStyle(color: Colors.white24, fontSize: 11)),
                  const SizedBox(height: 22),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AntigravityTheme.electricPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Verify & Continue →',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _showUniGate = false),
                      child: const Text('Go back',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
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
        title: const Text('🔥 Crash Report', style: TextStyle(color: Colors.redAccent)),
        content: SingleChildScrollView(
          child: Text(
            'Failed at: $location\n\nError:\n${e.toString()}\n\nStack Trace:\n$stackTrace',
            style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
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

