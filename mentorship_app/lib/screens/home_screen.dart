import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/antigravity_theme.dart';
import '../providers/app_providers.dart';
import '../models/app_user.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mentor_card.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final mentors = ref.watch(topMentorsProvider);

    final userName = currentUser.when(
      data: (u) => u?.name.split(' ').first ?? 'User',
      loading: () => '...',
      error: (_, __) => 'User',
    );
    
    final isMentee = currentUser.value?.role == 'mentee';
    final hasTags = (currentUser.value?.tags ?? []).isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AntigravityTheme.electricPurple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Explore',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      Text('Find your perfect mentor',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are all caught up! 🔔'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFF10B981), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Search bar ──────────────────────────────────
              GestureDetector(
                onTap: () {
                  context.push('/search-mentors');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1527),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: const TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: AntigravityTheme.electricPurple),
                      hintText: 'Search mentors, skills or branches',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Removed Filter chips ────────────────────────────────

              // ── Match Mentors ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isMentee ? 'Recommended for You' : 'Match Mentors',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(_isExpanded ? 'View less' : 'View all',
                        style: const TextStyle(
                            color: AntigravityTheme.electricPurple, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              isMentee && !hasTags
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1527),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.workspace_premium, size: 48, color: AntigravityTheme.electricPurple.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('Unlock AI Matchmaking', 
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Tell us your interests in your Profile to get AI-matched with mentors!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.push('/profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AntigravityTheme.electricPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Update Profile'),
                          ),
                        ],
                      ),
                    )
                  : isMentee
                      ? ref.watch(recommendedMentorsProvider).when(
                          data: (list) => list.isEmpty
                              ? _emptyState('No mentors found for your interests.')
                              : _buildMentorGrid(list),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => _emptyState('Could not load recommended mentors'),
                        )
                      : mentors.when(
                          data: (list) => list.isEmpty
                              ? _emptyState('No mentors found. Tap "Seed Sample Data" in Profile.')
                              : _buildMentorGrid(list),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => _emptyState('Could not load mentors'),
                        ),
              const SizedBox(height: 28),

              // ── Trending Topics ─────────────────────────────
              const Text('Trending Topics',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildTrendingTile(Icons.code_rounded, 'Coding Prep'),
                  const SizedBox(width: 12),
                  _buildTrendingTile(Icons.work_outline_rounded, 'Interview Tips'),
                  const SizedBox(width: 12),
                  _buildTrendingTile(Icons.design_services_rounded, 'UI/UX'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMentorGrid(List<AppUser> mentors) {
    final displayMentors = _isExpanded ? mentors : mentors.take(4).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: displayMentors.length,
      itemBuilder: (context, index) {
        return MentorCard(mentor: displayMentors[index]);
      },
    );
  }

  Widget _buildTrendingTile(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1527),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AntigravityTheme.electricPurple, size: 26),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 14))),
      );
}
