import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/antigravity_theme.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';
import '../services/firestore_seeder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserState = ref.watch(currentUserProvider);
    final uid = currentUserState.value?.id;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: AntigravityTheme.pureBlack,
        body: Center(child: CircularProgressIndicator(color: AntigravityTheme.electricPurple)),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AntigravityTheme.pureBlack,
            body: Center(child: CircularProgressIndicator(color: AntigravityTheme.electricPurple)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: AntigravityTheme.pureBlack,
            body: Center(child: Text('Profile not found', style: TextStyle(color: Colors.white))),
          );
        }

        final realtimeUser = AppUser.fromFirestore(snapshot.data!);

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AntigravityTheme.pureBlack,
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildProfileHeader(context, realtimeUser, ref),
                const SizedBox(height: 32),
                _buildMenuSection([
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'PERSONAL INFO',
                    onTap: () {
                      _showEditProfileModal(context, realtimeUser);
                    },
              ),
              Divider(height: 1, indent: 64, color: Colors.white.withValues(alpha: 0.08)),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'PREFERENCES',
              ),
            ]),
            const SizedBox(height: 16),
            _buildMenuSection([
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Support',
                subtitle: 'HELP CENTER',
              ),
            ]),
            const SizedBox(height: 32),
            // Seed Database button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await FirestoreSeeder().seedSampleMentors();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sample data seeded successfully!'),
                          backgroundColor: Color(0xFF22C55E),
                        ),
                      );
                      ref.invalidate(currentUserProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Seeding failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Seed Sample Data', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AntigravityTheme.electricPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _showLogoutDialog(context, ref),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'VERSION 2.4.0',
              style: TextStyle(
                color: AntigravityTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      ),
    );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppUser user, WidgetRef ref) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AntigravityTheme.midnightBlue,
                border: Border.all(
                  color: AntigravityTheme.electricPurple.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.person, size: 52, color: AntigravityTheme.textSecondary),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AntigravityTheme.electricPurple, AntigravityTheme.softBlue],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AntigravityTheme.pureBlack, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AntigravityTheme.textPrimary,
          ),
        ),
        if ((user.subtitle ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            user.subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: AntigravityTheme.textSecondary,
            ),
          ),
        ],
        if (user.role == 'mentor') ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Experience', '${user.yearsOfExperience ?? 0} yrs'),
              Container(height: 40, width: 1, color: Colors.white12),
              Consumer(
                builder: (context, ref, _) {
                  final studentCount = ref.watch(mentorStudentsCountProvider);
                  return _buildStatColumn('Students', studentCount.value?.toString() ?? '0');
                }
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  Widget _buildMenuSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AntigravityTheme.midnightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AntigravityTheme.electricPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AntigravityTheme.electricPurple, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AntigravityTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AntigravityTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AntigravityTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to end your session?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/welcome'); // Force immediate routing
                }
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileModal(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(user: user),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final AppUser user;

  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _collegeController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  
  late List<String> _tags;
  late bool _acceptingMentees;
  final TextEditingController _tagController = TextEditingController();
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _collegeController = TextEditingController(text: widget.user.subtitle ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _experienceController = TextEditingController(text: widget.user.yearsOfExperience?.toString() ?? '');
    
    _tags = List.from(widget.user.tags);
    _acceptingMentees = widget.user.acceptingMentees;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    
    final nameVal = _nameController.text.trim();
    if (nameVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final Map<String, dynamic> updateData = {
        'name': nameVal,
        'subtitle': _collegeController.text.trim(),
        'bio': _bioController.text.trim(),
        'tags': _tags,
      };

      if (widget.user.role == 'mentor') {
        updateData['yearsOfExperience'] = int.tryParse(_experienceController.text.trim()) ?? 0;
        updateData['acceptingMentees'] = _acceptingMentees;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update(updateData)
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AntigravityTheme.electricPurple),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMentor = widget.user.role == 'mentor';
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Profile',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('Basic Info'),
            _buildTextField('Full Name', _nameController),
            const SizedBox(height: 16),
            _buildTextField('College / Role', _collegeController),
            
            const SizedBox(height: 32),
            _buildSectionHeader('About'),
            _buildTextField('Bio', _bioController, maxLines: 3),
            
            const SizedBox(height: 32),
            _buildSectionHeader(isMentor ? 'Expertise' : 'Core Interests'),
            Text(isMentor ? 'Expertise Tags' : 'Core Interest Tags', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        backgroundColor: AntigravityTheme.electricPurple.withValues(alpha: 0.2),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                        side: BorderSide(color: AntigravityTheme.electricPurple.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            controller: _tagController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: isMentor ? 'Add an expertise tag...' : 'Add an interest tag...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onSubmitted: _addTag,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _addTag(_tagController.text),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AntigravityTheme.electricPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (isMentor) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('Availability'),
              _buildTextField('Years of Experience', _experienceController, hint: 'e.g. 5', keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              
              // Accepting Mentees Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Accepting Mentees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            _acceptingMentees ? 'You are visible to students' : 'Profile hidden from matchmaking',
                            style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _acceptingMentees,
                      onChanged: (val) => setState(() => _acceptingMentees = val),
                      activeColor: AntigravityTheme.electricPurple,
                      activeTrackColor: AntigravityTheme.electricPurple.withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white12,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AntigravityTheme.electricPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: AntigravityTheme.electricPurple.withValues(alpha: 0.5),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('SAVE CHANGES',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 120), // ADDED: Extra padding for Bug 2
          ],
        ),
      ),
      ),
    );
  }

  void _addTag(String val) {
    if (val.trim().isNotEmpty && !_tags.contains(val.trim())) {
      setState(() {
        _tags.add(val.trim());
        _tagController.clear();
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hint, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
