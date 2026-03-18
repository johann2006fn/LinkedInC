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
        body: Center(
          child: CircularProgressIndicator(
            color: AntigravityTheme.electricPurple,
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AntigravityTheme.pureBlack,
            body: Center(
              child: CircularProgressIndicator(
                color: AntigravityTheme.electricPurple,
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: AntigravityTheme.pureBlack,
            body: Center(
              child: Text(
                'Profile not found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final realtimeUser = AppUser.fromFirestore(snapshot.data!);
        final isMentor = realtimeUser.role == 'mentor';

        return Scaffold(
          backgroundColor: AntigravityTheme.pureBlack,
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityHeader(context, realtimeUser),
                const SizedBox(height: 32),

                if (isMentor) ...[
                  _buildMentorshipImpact(context, realtimeUser),
                  const SizedBox(height: 32),
                ],

                // Communication & Discovery Preferences
                const Text(
                  'PREFERENCES',
                  style: TextStyle(
                    color: AntigravityTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuSection([
                  _buildToggleItem(
                    icon: Icons.video_call_outlined,
                    title: 'Allow Video Calls',
                    value:
                        (realtimeUser.preferences?['allowsVideo'] as bool?) ??
                        true,
                    onChanged: (val) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                            'preferences': {'allowsVideo': val},
                          }, SetOptions(merge: true));
                    },
                  ),
                  if (isMentor) ...[
                    Divider(
                      height: 1,
                      indent: 60,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    _buildToggleItem(
                      icon: Icons.search_outlined,
                      title: 'Accepting New Matches',
                      value: realtimeUser.acceptingMentees,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({'acceptingMentees': val});
                      },
                    ),
                  ],
                ]),
                const SizedBox(height: 32),

                // Profile Utilities
                const Text(
                  'UTILITIES',
                  style: TextStyle(
                    color: AntigravityTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuSection([
                  _buildMenuItem(
                    icon: Icons.visibility_outlined,
                    title: 'View Public Profile',
                    onTap: () {
                      if (isMentor) {
                        context.push('/mentor-detail', extra: realtimeUser);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Public profile view is currently only available for mentors.'),
                          ),
                        );
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 32),

                // Account Management
                const Text(
                  'ACCOUNT MANAGEMENT',
                  style: TextStyle(
                    color: AntigravityTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuSection([
                  _buildMenuItem(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile Details',
                    onTap: () => _showEditProfileModal(context, realtimeUser),
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About MentorHub',
                    onTap: () => _showAboutMentorHub(context),
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  _buildMenuItem(
                    icon: Icons.logout_outlined,
                    title: 'Log Out',
                    titleColor: const Color(0xFFEF4444),
                    iconColor: const Color(0xFFEF4444),
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ]),

                const SizedBox(height: 32),
                // Testing scaffolding (Keep as requested previously)
                if (isMentor)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await FirestoreSeeder().seedMentorData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Mentor test data injected! Check your Calendar & Dashboard.',
                                ),
                                backgroundColor: Color(0xFF22C55E),
                              ),
                            );
                            ref.invalidate(currentUserProvider);
                            ref.invalidate(pendingRequestsProvider);
                            ref.invalidate(upcomingSessionsProvider);
                            ref.invalidate(mentorStudentsCountProvider);
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
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text(
                        'Debug: Setup Mentor Data',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'VERSION 1.1.0',
                    style: TextStyle(
                      color: AntigravityTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityHeader(BuildContext context, AppUser user) {
    // Calculate profile completion logic
    int completedCount = 0;
    int totalFields = 4;
    if ((user.bio ?? '').isNotEmpty) completedCount++;
    if (user.tags.isNotEmpty) completedCount++;
    if ((user.profileImageUrl ?? '').isNotEmpty) completedCount++;
    if ((user.subtitle ?? '').isNotEmpty) completedCount++;
    final completionProgress = completedCount / totalFields;

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
              child: const Icon(
                Icons.person,
                size: 52,
                color: AntigravityTheme.textSecondary,
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
              fontSize: 14,
              color: AntigravityTheme.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Completion',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(completionProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AntigravityTheme.electricPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completionProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AntigravityTheme.electricPurple,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
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

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AntigravityTheme.electricPurple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AntigravityTheme.electricPurple, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AntigravityTheme.textPrimary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AntigravityTheme.electricPurple,
        inactiveTrackColor: Colors.white24,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color titleColor = AntigravityTheme.textPrimary,
    Color iconColor = AntigravityTheme.electricPurple,
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
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: titleColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AntigravityTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorshipImpact(BuildContext context, AppUser user) {
    final sortedEndorsements = user.endorsements.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MENTORSHIP IMPACT',
              style: TextStyle(
                color: AntigravityTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF10B981), size: 12),
                  SizedBox(width: 4),
                  Text(
                    '100% Recommended',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AntigravityTheme.electricPurple.withValues(alpha: 0.15),
                AntigravityTheme.softBlue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildImpactStat(
                    'Sessions',
                    user.sessionsCompleted.toString(),
                    Icons.verified_outlined,
                  ),
                  Container(width: 1, height: 40, color: Colors.white10),
                  _buildImpactStat(
                    'Endorsements',
                    user.totalEndorsements.toString(),
                    Icons.military_tech,
                  ),
                  Container(width: 1, height: 40, color: Colors.white10),
                  _buildImpactStat(
                    'Top Skill',
                    user.topEndorsementTag ?? '—',
                    Icons.workspace_premium_outlined,
                  ),
                ],
              ),
              if (sortedEndorsements.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 16),
                const Text(
                  'COMMUNITY TAGS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedEndorsements
                      .map(
                        (entry) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  color: AntigravityTheme.electricPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AntigravityTheme.electricPurple, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AntigravityTheme.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutMentorHub(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AntigravityTheme.electricPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.hub,
                          color: AntigravityTheme.electricPurple,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'MentorHub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Version 1.1.0',
                        style: TextStyle(
                          color: AntigravityTheme.electricPurple,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '© 2026 Antigravity Inc.',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.white10),
                // Scrollable legal content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Privacy Policy
                        const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'MentorHub is a college mentorship platform designed to connect '
                          'students with experienced mentors within their institution. '
                          'We take your privacy seriously.\n\n'
                          'Data Collection: We collect your name, email, college affiliation, '
                          'academic interests, and mentoring preferences to facilitate meaningful '
                          'mentor-mentee matching. Profile data is stored securely via Google Firebase.\n\n'
                          'Data Usage: Your information is used exclusively to power AI-driven '
                          'matchmaking, enable in-app communication, and improve the mentoring '
                          'experience. We do not sell or share your personal data with third parties.\n\n'
                          'Data Retention: Your data is retained while your account is active. '
                          'You may request account deletion at any time by contacting your '
                          'college administrator or emailing support@mentorhub.app.\n\n'
                          'Video Calls: MentorHub uses Jitsi Meet for video sessions. Video calls '
                          'are peer-to-peer and are not recorded or stored by MentorHub.\n\n'
                          'Analytics: We collect anonymous usage analytics to improve app performance '
                          'and user experience. No personally identifiable information is included.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // User Guidelines
                        const Text(
                          'User Guidelines',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Respect & Inclusion: Treat all mentors and mentees with respect. '
                          'Harassment, discrimination, or abusive behavior of any kind will result '
                          'in immediate account suspension.\n\n'
                          '2. Academic Integrity: Do not use MentorHub to solicit or provide '
                          'answers for exams, assignments, or other assessed work. Mentorship '
                          'should focus on guidance, skill development, and career advice.\n\n'
                          '3. Professionalism: Keep all communications professional and relevant '
                          'to mentoring. Do not share inappropriate content or use the platform '
                          'for non-academic solicitation.\n\n'
                          '4. Identity Verification: Your college identity has been verified. '
                          'Do not share your credentials or impersonate another user.\n\n'
                          '5. Session Etiquette: Honor scheduled mentoring sessions. If you need '
                          'to cancel, provide at least 24 hours notice through the app.\n\n'
                          '6. Privacy: Do not share private conversations, session recordings, '
                          'or personal contact details of other users outside the platform.\n\n'
                          '7. Reporting: Use the in-app reporting feature to flag any violations. '
                          'All reports are reviewed within 48 hours by the moderation team.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        backgroundColor: AntigravityTheme.electricPurple.withValues(alpha: 0.15),
                        foregroundColor: AntigravityTheme.electricPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/welcome');
                }
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
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
    _collegeController = TextEditingController(
      text: widget.user.subtitle ?? '',
    );
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _experienceController = TextEditingController(
      text: widget.user.yearsOfExperience?.toString() ?? '',
    );

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
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.redAccent,
        ),
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
        updateData['yearsOfExperience'] =
            int.tryParse(_experienceController.text.trim()) ?? 0;
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
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AntigravityTheme.electricPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
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
          left: 24,
          right: 24,
          top: 12,
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
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              Text(
                isMentor ? 'Expertise Tags' : 'Core Interest Tags',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map(
                              (tag) => Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: AntigravityTheme.electricPurple
                                    .withValues(alpha: 0.2),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onDeleted: () =>
                                    setState(() => _tags.remove(tag)),
                                side: BorderSide(
                                  color: AntigravityTheme.electricPurple
                                      .withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                              ),
                            )
                            .toList(),
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
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: TextField(
                              controller: _tagController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: isMentor
                                    ? 'Add an expertise tag...'
                                    : 'Add an interest tag...',
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
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
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
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
                _buildTextField(
                  'Years of Experience',
                  _experienceController,
                  hint: 'e.g. 5',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Accepting Mentees Switch
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accepting Mentees',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _acceptingMentees
                                  ? 'You are visible to students'
                                  : 'Profile hidden from matchmaking',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _acceptingMentees,
                        onChanged: (val) =>
                            setState(() => _acceptingMentees = val),
                        activeThumbColor: AntigravityTheme.electricPurple,
                        activeTrackColor: AntigravityTheme.electricPurple
                            .withValues(alpha: 0.3),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AntigravityTheme.electricPurple
                        .withValues(alpha: 0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
