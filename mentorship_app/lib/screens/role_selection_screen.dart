import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/glass_container.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;
  final List<String> _allTags = ['Flutter', 'AI/ML', 'Design', 'Python', 'Marketing', 'Backend', 'Product'];
  final List<String> _selectedTags = [];

  Future<void> _saveRoleAndContinue() async {
    if (_isLoading) return; // Prevent double-tap
    if (_selectedRole == null) return;
    if (_selectedRole == null) return;
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid;
      
      // LOGICAL FLAW: We shouldn't silently return if uid is null without notifying
      if (uid == null) {
        throw Exception("currentUser.uid is null! User session was lost securely before Role Selection.");
      }
      print('DEBUG: [Get Current User] Successful');

      // Create or update the user document with the selected role and tags
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': _selectedRole == 'mentee' ? 'student' : 'mentor',
        'name': currentUser!.displayName ?? '',
        'email': currentUser.email ?? '',
        'profileImageUrl': currentUser.photoURL,
        'tags': _selectedTags,
        'isProfileComplete': false,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Network timeout: Could not save role and tags. Please check your connection.');
      });
      print('DEBUG: [Save User Role and Tags] Successful');

      if (mounted) {
        if (_selectedRole == 'mentee') {
          context.go('/onboarding/mentee');
        } else {
          context.go('/onboarding/mentor');
        }
      }
    } catch (e, stackTrace) {
      print('ERROR: Failed at [Save User Role and Tags] - $e');
      _showCrashReport(e, stackTrace, 'Save User Role and Tags');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AntigravityTheme.pureBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/auth'),
          color: AntigravityTheme.textSecondary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How do you want to participate?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      role: 'mentee',
                      title: 'Learn',
                      subtitle: 'Find a mentor',
                      icon: Icons.explore_rounded,
                      glowColor: AntigravityTheme.softBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoleCard(
                      role: 'mentor',
                      title: 'Guide',
                      subtitle: 'Share expertise',
                      icon: Icons.auto_awesome_rounded,
                      glowColor: AntigravityTheme.electricPurple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              const Text(
                'What are your core interests?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose tags to personalize your experience',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 20),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AntigravityTheme.electricPurple : AntigravityTheme.midnightBlue,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? Colors.white24 : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 100), // padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedRole != null
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _saveRoleAndContinue,
              backgroundColor: AntigravityTheme.electricPurple,
              label: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
              icon: _isLoading
                  ? null
                  : const Icon(Icons.arrow_forward, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color glowColor,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        height: 160,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: glowColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
          ],
        ),
        child: GlassContainer(
          borderRadius: 24,
          borderColor: isSelected ? glowColor : Colors.white.withOpacity(0.05),
          backgroundColor: isSelected ? glowColor.withOpacity(0.1) : AntigravityTheme.midnightBlue,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: glowColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: glowColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AntigravityTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
