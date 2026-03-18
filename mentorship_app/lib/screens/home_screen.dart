// ignore_for_file: unnecessary_underscores
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/app_providers.dart';
import '../models/app_user.dart';
import '../widgets/notification_sheet.dart';
import '../models/mentor_match.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/mentor_card.dart';
import '../widgets/user_avatar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isMentee =
        userAsync.value?.role == 'student' || userAsync.value?.role == 'mentee';
    final hasTags = userAsync.value?.tags.isNotEmpty ?? false;
    final mentors = ref.watch(topMentorsProvider);

    return Scaffold(
      backgroundColor: AntigravityTheme.pureBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (userAsync.value != null) {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          backgroundColor: const Color(0xFF1A1527),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => Container(
                            padding: const EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 24,
                              bottom: 40,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                UserAvatar(user: userAsync.value!, radius: 40),
                                const SizedBox(height: 16),
                                Text(
                                  userAsync.value!.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userAsync.value!.email,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push('/profile');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Manage Full Profile',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: userAsync.value != null
                        ? UserAvatar(user: userAsync.value!, radius: 21)
                        : Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AntigravityTheme.electricPurple,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${userAsync.value?.name.split(' ').first ?? 'User'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Find your perfect mentor',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (userAsync.value != null)
                    NotificationSheet.bellIcon(
                      userId: userAsync.value!.id,
                      onPressed: () =>
                          NotificationSheet.show(context, userAsync.value!.id),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: const TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.search,
                        color: AntigravityTheme.electricPurple,
                      ),
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

              if (isMentee && hasTags) ...[
                Text(
                  'Curated for your goals in ${userAsync.value!.tags.isEmpty ? '' : userAsync.value!.tags.take(2).join(" & ")}'
                      .trim(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Removed Filter chips ────────────────────────────────

              // ── Match Mentors ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended for You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(
                      _isExpanded ? 'View less' : 'View all',
                      style: const TextStyle(
                        color: AntigravityTheme.electricPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!hasTags) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1527),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 48,
                        color: AntigravityTheme.electricPurple.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unlock AI Matchmaking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tell us your interests in your Profile to get AI-matched with mentors!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.push('/profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AntigravityTheme.electricPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Update Profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Trending Mentors',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                mentors.when(
                  data: (list) => list.isEmpty
                      ? _emptyState('No trending mentors found.')
                      : _buildMentorGrid(list),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _emptyState('Could not load mentors'),
                ),
              ] else ...[
                ref
                    .watch(geminiMatchesProvider)
                    .when(
                      data: (matches) => matches.isEmpty
                          ? _emptyState('No AI matches found for your profile.')
                          : _buildMatchGrid(matches),
                      loading: () => _buildShimmerGrid(),
                      error: (e, _) => _emptyState(
                        'Could not load recommended mentors. Ensure API key is set.',
                      ),
                    ),
              ],
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
        childAspectRatio: 0.75,
      ),
      itemCount: displayMentors.length,
      itemBuilder: (context, index) {
        return MentorCard(mentor: displayMentors[index]);
      },
    );
  }

  Widget _buildMatchGrid(List<MentorMatch> matches) {
    final displayMatches = _isExpanded ? matches : matches.take(4).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58, // Increased height for match reason and status
      ),
      itemCount: displayMatches.length,
      itemBuilder: (context, index) {
        final match = displayMatches[index];
        return MentorCard(match: match);
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white38, fontSize: 14),
      ),
    ),
  );
}
