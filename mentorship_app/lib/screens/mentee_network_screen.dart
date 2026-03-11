import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/antigravity_theme.dart';
import '../providers/app_providers.dart';
import '../models/app_user.dart';

class MenteeNetworkScreen extends ConsumerStatefulWidget {
  const MenteeNetworkScreen({super.key});

  @override
  ConsumerState<MenteeNetworkScreen> createState() => _MenteeNetworkScreenState();
}

class _MenteeNetworkScreenState extends ConsumerState<MenteeNetworkScreen> with SingleTickerProviderStateMixin {
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
    // For "Saved", we'll mock it by taking some mentors from topMentors
    final allMentors = ref.watch(topMentorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B14),
        elevation: 0,
        title: const Text('My Network',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AntigravityTheme.electricPurple,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    msg: 'You haven\'t connected with any mentors. Explore the Matchmaking Feed to find your perfect guide.',
                    icon: Icons.people_outline_rounded,
                    buttonText: 'Find Mentors',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _buildConnectionCard(list[i]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _emptyState(
              title: 'Error',
              msg: 'Could not load connections',
              icon: Icons.error_outline,
            ),
          ),

          // ── Saved Tab ───────────────────────────────────
          allMentors.when(
            data: (list) {
              final saved = list.take(2).toList(); // Mocking saved
              return saved.isEmpty
                  ? _emptyState(
                      title: 'No Saved Profiles',
                      msg: 'Profiles you save for later will appear here. Start browsing to build your shortlist!',
                      icon: Icons.bookmark_border_rounded,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      itemCount: saved.length,
                      itemBuilder: (_, i) => _buildSavedCard(saved[i]),
                    );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _emptyState(
              title: 'Error',
              msg: 'Could not load saved mentors',
              icon: Icons.error_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(dynamic conn) {
    // Basic mock connection card with progress bar
    final progress = 0.6; // Mock progress
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
                  conn.mentorName.isNotEmpty ? conn.mentorName[0].toUpperCase() : 'M',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conn.mentorName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Senior Product Designer',
                        style: TextStyle(color: AntigravityTheme.electricPurple, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.white38),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mentorship Progress',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF2D2040),
              valueColor: const AlwaysStoppedAnimation(AntigravityTheme.electricPurple),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2040),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text('Schedule Session',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCard(AppUser mentor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1527),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2D2040),
            child: Text(
              mentor.name.isNotEmpty ? mentor.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mentor.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(mentor.subtitle ?? 'Expert Mentor',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark, color: AntigravityTheme.electricPurple),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyState({required String title, required String msg, required IconData icon, String? buttonText}) => Center(
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
                child: Icon(icon, size: 48, color: AntigravityTheme.electricPurple.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.4)),
              if (buttonText != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Route to home to find mentors
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AntigravityTheme.electricPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      );
}
