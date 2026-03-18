import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/glass_container.dart';

class MentorOnboardingScreen extends StatefulWidget {
  const MentorOnboardingScreen({super.key});

  @override
  State<MentorOnboardingScreen> createState() => _MentorOnboardingScreenState();
}

class _MentorOnboardingScreenState extends State<MentorOnboardingScreen> {
  final TextEditingController _skillsController = TextEditingController();
  final List<String> _skills = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _skillsController.addListener(_extractSkills);
  }

  @override
  void dispose() {
    _skillsController.removeListener(_extractSkills);
    _skillsController.dispose();
    super.dispose();
  }

  void _extractSkills() {
    final text = _skillsController.text;
    if (text.contains(',')) {
      final parts = text.split(',');
      final currentTags = parts
          .take(parts.length - 1)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      setState(() {
        for (var tag in currentTags) {
          if (!_skills.contains(tag)) {
            _skills.add(tag);
          }
        }
      });

      final remainingData = parts.last.trimLeft();
      _skillsController.value = TextEditingValue(
        text: remainingData,
        selection: TextSelection.collapsed(offset: remainingData.length),
      );
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return; // Prevent double-tap
    // Also include whatever text is still in the text field
    final remaining = _skillsController.text.trim();
    if (remaining.isNotEmpty && !_skills.contains(remaining)) {
      _skills.add(remaining);
    }

    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception(
          "currentUser.uid is null! User session lost before saving Mentor Skills.",
        );
      }
      debugPrint('DEBUG: [Get Current User for Mentor Skills] Successful');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
            'skills': _skills,
            'bio': 'Expert in ${_skills.join(", ")}',
            'acceptingMentees': true,
            'maxMentees': 3,
          }, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Network timeout: Could not save skills and bio. Please check your connection.',
              );
            },
          );
      debugPrint('DEBUG: [Save Mentor Skills] Successful');
      if (mounted) context.push('/onboarding/preferences');
    } catch (e, stackTrace) {
      debugPrint('ERROR: Failed at [Save Mentor Skills] - $e');
      _showCrashReport(e, stackTrace, 'Save Mentor Skills');
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
                // Minimalist Progress Bar
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
                  'What are your\nsuperpower skills?',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(height: 1.2),
                ),
                const SizedBox(height: 32),

                // Floating Text Input Box
                GlassContainer(
                  child: TextField(
                    controller: _skillsController,
                    style: const TextStyle(
                      color: AntigravityTheme.textPrimary,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. React Native, Node.js, Agile...',
                      hintStyle: TextStyle(
                        color: AntigravityTheme.textSecondary.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Floating pill tags
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12.0,
                      runSpacing: 16.0,
                      children: _skills.map((skill) {
                        return Draggable<String>(
                          data: skill,
                          feedback: _buildGlowingPill(skill, isDragging: true),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildGlowingPill(skill),
                          ),
                          child: _buildGlowingPill(skill),
                        );
                      }).toList(),
                    ),
                  ),
                ),
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

  Widget _buildGlowingPill(String skill, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AntigravityTheme.softBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AntigravityTheme.softBlue.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AntigravityTheme.softBlue.withValues(
                alpha: isDragging ? 0.6 : 0.3,
              ),
              blurRadius: isDragging ? 20 : 10,
              spreadRadius: isDragging ? 5 : 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skill,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeSkill(skill),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white70),
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
