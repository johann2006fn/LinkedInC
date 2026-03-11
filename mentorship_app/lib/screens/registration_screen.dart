import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearController = TextEditingController();

  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _codeVerified = false;
  bool _codeChecking = false;
  String? _codeError;

  final List<String> _selectedInterests = [];
  final List<String> _selectedSkills = [];

  static const _availableInterests = [
    'Machine Learning', 'Web Dev', 'Mobile Dev', 'Data Science',
    'Cloud Computing', 'Cybersecurity', 'UI/UX Design', 'Blockchain',
    'Research', 'Entrepreneurship', 'Open Source', 'Game Dev',
  ];

  static const _availableSkills = [
    'Python', 'Java', 'Flutter/Dart', 'JavaScript', 'React',
    'Node.js', 'SQL', 'Firebase', 'Git', 'Docker', 'Figma', 'C++',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google account
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) return;
    setState(() {
      _codeChecking = true;
      _codeError = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final valid = await authService.verifyCollegeCode(_codeController.text);
      setState(() {
        _codeVerified = valid;
        _codeError = valid ? null : 'Invalid college code. Please check and try again.';
        _codeChecking = false;
      });
    } catch (e) {
      setState(() {
        _codeError = 'Verification failed. Try again.';
        _codeChecking = false;
      });
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_codeVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your college code first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final authService = ref.read(authServiceProvider);
      final appUser = AppUser(
        id: user.uid,
        name: _nameController.text.trim(),
        email: user.email ?? '',
        role: _selectedRole,
        profileImageUrl: user.photoURL,
        subtitle: _selectedRole == 'mentor'
            ? '${_departmentController.text.trim()} • ${_yearController.text.trim()}'
            : '${_departmentController.text.trim()} • ${_yearController.text.trim()}',
        tags: [..._selectedInterests, ..._selectedSkills],
        collegeCode: _codeController.text.trim().toUpperCase(),
        bio: _bioController.text.trim(),
        skills: List.from(_selectedSkills),
        interests: List.from(_selectedInterests),
        goals: [],
        department: _departmentController.text.trim(),
        year: _yearController.text.trim(),
      );

      await authService.createUserProfile(appUser);

      if (!mounted) return;
      if (_selectedRole == 'mentor') {
        context.go('/mentor');
      } else {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Header
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tell us a bit about yourself to get the best matches.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- COLLEGE CODE ---
                  _sectionLabel('College Code'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _codeController,
                          hint: 'Enter your college code (e.g. VIT2026)',
                          textCapitalization: TextCapitalization.characters,
                          suffixIcon: _codeVerified
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF4ADE80))
                              : null,
                          onChanged: (_) {
                            if (_codeVerified) {
                              setState(() => _codeVerified = false);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _codeChecking ? null : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ADE80),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _codeChecking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text('Verify',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  if (_codeError != null) ...[
                    const SizedBox(height: 6),
                    Text(_codeError!,
                        style: const TextStyle(
                            color: Color(0xFFFF6B6B), fontSize: 12)),
                  ],

                  const SizedBox(height: 24),
                  // --- ROLE SELECTION ---
                  _sectionLabel('I am a…'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _roleCard('student', 'Student / Mentee',
                          Icons.school_rounded, 'Looking for guidance'),
                      const SizedBox(width: 12),
                      _roleCard('mentor', 'Mentor',
                          Icons.workspace_premium_rounded, 'Ready to guide'),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // --- NAME ---
                  _sectionLabel('Full Name'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Your full name',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 20),
                  // --- DEPARTMENT ---
                  _sectionLabel('Department'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _departmentController,
                    hint: 'e.g. Computer Science',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 20),
                  // --- YEAR ---
                  _sectionLabel(
                      _selectedRole == 'mentor' ? 'Years of Experience' : 'Year / Batch'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _yearController,
                    hint: _selectedRole == 'mentor'
                        ? 'e.g. 5 years'
                        : 'e.g. Class of 2027',
                  ),

                  const SizedBox(height: 20),
                  // --- BIO ---
                  _sectionLabel('Short Bio'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _bioController,
                    hint: 'Tell mentors/mentees about yourself…',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),
                  // --- INTERESTS ---
                  _sectionLabel('Interests'),
                  const SizedBox(height: 10),
                  _chipSelector(_availableInterests, _selectedInterests),

                  const SizedBox(height: 20),
                  // --- SKILLS ---
                  _sectionLabel('Skills'),
                  const SizedBox(height: 10),
                  _chipSelector(_availableSkills, _selectedSkills),

                  const SizedBox(height: 36),
                  // --- SUBMIT ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _selectedRole == 'mentor'
                                  ? 'Become a Mentor →'
                                  : 'Find My Mentor →',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6C63FF)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
      ),
    );
  }

  Widget _roleCard(
      String role, String title, IconData icon, String subtitle) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6C63FF).withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6C63FF)
                  : Colors.white.withOpacity(0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? const Color(0xFF6C63FF) : Colors.white54),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipSelector(List<String> options, List<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selected.remove(option);
              } else {
                selected.add(option);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6C63FF)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
