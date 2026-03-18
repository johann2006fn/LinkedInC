// ignore_for_file: unnecessary_underscores
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/antigravity_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/saved_mentors_tab.dart';

class MenteeNetworkScreen extends ConsumerStatefulWidget {
  const MenteeNetworkScreen({super.key});

  @override
  ConsumerState<MenteeNetworkScreen> createState() =>
      _MenteeNetworkScreenState();
}

class _MenteeNetworkScreenState extends ConsumerState<MenteeNetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connections = ref.watch(activeMentorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B14),
        elevation: 0,
        title: const Text(
          'My Network',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AntigravityTheme.electricPurple,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'My Mentors'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── My Mentors Tab ──────────────────────────────
          connections.when(
            data: (list) => list.isEmpty
                ? _emptyState(
                    title: 'No Mentors Yet',
                    msg:
                        'You haven\'t connected with any mentors. Explore the Matchmaking Feed to find your perfect guide.',
                    icon: Icons.people_outline_rounded,
                    buttonText: 'Find Mentors',
                    onButtonPressed: () => context.go('/'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _buildConnectionCard(ctx, list[i]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _emptyState(
              title: 'Error',
              msg: 'Could not load connections',
              icon: Icons.error_outline,
            ),
          ),

          // ── Saved Tab ─── uses actual provider ──────────
          const SavedMentorsTab(),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, dynamic conn) {
    final mentorName = conn.mentorName ?? 'Mentor';
    final mentorSubtitle = conn.mentorSubtitle ?? '';

    // Compute a basic progress from sessions completed (connection-level)
    // MentorshipConnection currently lacks a sessionsCompleted property. Defaulting to 0.
    final sessionsCompleted = 0;
    final targetSessions = 10; // reasonable goal
    final progress = (sessionsCompleted / targetSessions).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1527),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2D2040),
                child: Text(
                  mentorName.isNotEmpty
                      ? mentorName[0].toUpperCase()
                      : 'M',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (mentorSubtitle.isNotEmpty)
                      Text(
                        mentorSubtitle,
                        style: const TextStyle(
                          color: AntigravityTheme.electricPurple,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                    SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$sessionsCompleted / $targetSessions sessions',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF2D2040),
              valueColor: const AlwaysStoppedAnimation(
                AntigravityTheme.electricPurple,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final otherUserId = conn.mentorId as String? ?? '';
                      if (otherUserId.isEmpty) return;
                      final currentUser = ref.read(currentUserProvider).value;
                      if (currentUser == null) return;

                      final chatId = await ref
                          .read(chatRepositoryProvider)
                          .getOrCreateChatId(currentUser.id, otherUserId);

                      if (!context.mounted) return;
                      context.push('/chat/$chatId');
                    } catch (e) {
                      debugPrint('Network message error: $e');
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text(
                    'Message',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final otherUserId = conn.mentorId as String? ?? '';
                      if (otherUserId.isEmpty) return;
                      final currentUser = ref.read(currentUserProvider).value;
                      if (currentUser == null) return;

                      final chatId = await ref
                          .read(chatRepositoryProvider)
                          .getOrCreateChatId(currentUser.id, otherUserId);

                      if (!context.mounted) return;
                      context.push('/chat/$chatId');
                    } catch (e) {
                      debugPrint('Network schedule error: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2040),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Schedule Session',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required String title,
    required String msg,
    required IconData icon,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(
              icon,
              size: 48,
              color: AntigravityTheme.electricPurple.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AntigravityTheme.electricPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
