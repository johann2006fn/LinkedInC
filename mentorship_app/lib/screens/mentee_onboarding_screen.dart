import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/glass_container.dart';

class MenteeOnboardingScreen extends StatefulWidget {
  const MenteeOnboardingScreen({super.key});

  @override
  State<MenteeOnboardingScreen> createState() => _MenteeOnboardingScreenState();
}

class _MenteeOnboardingScreenState extends State<MenteeOnboardingScreen> {
  final TextEditingController _goalController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return; // Prevent double-tap
    final text = _goalController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your challenge first')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception(
          "currentUser.uid is null! User session lost before saving Mentee Goals.",
        );
      }
      debugPrint('DEBUG: [Get Current User for Mentee Goals] Successful');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
            'goals': [text],
            'bio': text,
          }, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Network timeout: Could not save goals. Please check your connection.',
              );
            },
          );
      debugPrint('DEBUG: [Save Mentee Goals] Successful');

      if (mounted) context.push('/onboarding/preferences');
    } catch (e, stackTrace) {
      debugPrint('ERROR: Failed at [Save Mentee Goals] - $e');
      _showCrashReport(e, stackTrace, 'Save Mentee Goals');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/role-selection');
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
        backgroundColor: AntigravityTheme.pureBlack,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/role-selection'),
            color: AntigravityTheme.textSecondary,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing Progress Bar (Step 1 of 3)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: AntigravityTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AntigravityTheme.electricPurple.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Step 1 of 3',
                  style: TextStyle(
                    color: AntigravityTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 48),

                Text(
                  'What is your biggest\nchallenge right now?',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(height: 1.2),
                ),
                const SizedBox(height: 32),

                // Floating Text Area
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: TextField(
                      controller: _goalController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        color: AntigravityTheme.textPrimary,
                        fontSize: 18,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'I am trying to transition from front-end to full-stack, but struggling with system design...',
                        hintStyle: TextStyle(
                          color: AntigravityTheme.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 18,
                          height: 1.5,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AntigravityTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AntigravityTheme.electricPurple.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _isSaving ? null : _saveAndContinue,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
          ),
        ),
      ),
    ));
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
