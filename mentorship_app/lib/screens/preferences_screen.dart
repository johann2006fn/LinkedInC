import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/gradient_button.dart';
import '../services/matchmaking_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String? _selectedIdentity;
  String? _selectedPreference;
  String? _selectedCommunication;
  bool _isSaving = false;

  bool _isProfileComplete() {
    return _selectedIdentity != null && 
           _selectedPreference != null && 
           _selectedCommunication != null;
  }

  Future<void> _completeProfile() async {
    if (!_isProfileComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final role = doc.data()?['role'] ?? 'student';

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'gender': _selectedIdentity,
          'preferences': {
            'connectWith': _selectedPreference,
            'communicationStyle': _selectedCommunication,
          },
          'isProfileComplete': true,
          'onboardingCompletedAt': FieldValue.serverTimestamp(),
        });

        // Re-fetch the full user doc AFTER saving preferences so the embedding
        // is built from the complete profile: bio + goals (from MenteeOnboardingScreen)
        // + gender/preferences (just saved above).
        final freshDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        
        // This is where it talks to Gemini
        await MatchmakingService()
            .generateAndSaveEmbedding(uid, freshDoc.data() ?? {});

        if (mounted) {
          // Route to the correct dashboard based on role
          if (role == 'mentor') {
            context.go('/mentor');
          } else {
            context.go('/');
          }
        }
      }
    } catch (e) {
      // 🚨 ADDED PRINT STATEMENT HERE TO CATCH THE EXACT ERROR
      print("🚨 GEMINI ERROR: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AntigravityTheme.pureBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
          color: AntigravityTheme.textSecondary,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tailor your\nexperience.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 48),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildQuestionSection(
                        title: 'I identify as:',
                        options: ['Male', 'Female', 'Non-binary', 'Prefer not to say'],
                        selectedOption: _selectedIdentity,
                        onChanged: (val) => setState(() => _selectedIdentity = val),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildQuestionSection(
                        title: 'I prefer to connect with:',
                        options: ['Anyone', 'Same gender'],
                        selectedOption: _selectedPreference,
                        onChanged: (val) => setState(() => _selectedPreference = val),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildQuestionSection(
                        title: 'Communication style:',
                        options: ['Video Calls', 'Text Only', 'Both'],
                        selectedOption: _selectedCommunication,
                        onChanged: (val) => setState(() => _selectedCommunication = val),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),

              GradientButton(
                text: 'Complete Profile',
                isLoading: _isSaving,
                onPressed: _completeProfile,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionSection({
    required String title,
    required List<String> options,
    required String? selectedOption,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AntigravityTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12.0,
          runSpacing: 16.0,
          children: options.map((option) {
            final isSelected = selectedOption == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AntigravityTheme.electricPurple.withOpacity(0.15) 
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected 
                        ? AntigravityTheme.electricPurple 
                        : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AntigravityTheme.electricPurple.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AntigravityTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}