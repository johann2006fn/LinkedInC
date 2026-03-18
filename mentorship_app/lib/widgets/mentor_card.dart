import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/mentor_match.dart';
import '../theme/antigravity_theme.dart';
import 'package:go_router/go_router.dart';
import '../widgets/user_avatar.dart';
import '../providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MentorCard extends ConsumerWidget {
  final MentorMatch? match;
  final AppUser? mentor;

  const MentorCard({super.key, this.match, this.mentor})
    : assert(match != null || mentor != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialMentor = mentor ?? match!.mentor;
    final displayMentorAsync = ref.watch(userStreamProvider(initialMentor.id));
    final displayMentor = displayMentorAsync.value ?? initialMentor;

    final currentUser = ref.watch(currentUserProvider).value;
    final isSaved =
        currentUser?.savedMentors.contains(displayMentor.id) ?? false;

    // AI Match Real-time overrides
    final matchScore = displayMentor.matchScore > 0
        ? displayMentor.matchScore
        : (match?.score ?? 0);
        
    final matchReason = displayMentor.matchReason?.isNotEmpty == true
        ? displayMentor.matchReason!
        : (match?.reason ?? '');
        
    final hasMatchData = matchScore > 0 || matchReason.isNotEmpty;

    final firstName = displayMentor.name.split(' ').first;

    // Years of experience display
    final yoeText = displayMentor.yearsOfExperience != null
        ? '${displayMentor.yearsOfExperience} yrs exp'
        : (displayMentor.experience ?? displayMentor.year);

    return GestureDetector(
      onTap: () => context.push(
        '/mentor-detail',
        extra: {
          'mentor': displayMentor,
          'matchScore': matchScore > 0 ? matchScore.toDouble() : null,
          'matchReason': matchReason.isNotEmpty ? matchReason : null,
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AntigravityTheme.softBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AntigravityTheme.softBlue.withValues(alpha: 0.15),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + Bookmark ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 52,
                  child: UserAvatar(user: displayMentor, radius: 26),
                ),
                IconButton(
                  onPressed: () {
                    if (currentUser != null) {
                      ref
                          .read(userRepositoryProvider)
                          .toggleSaveMentor(
                            currentUser.id,
                            displayMentor.id,
                            !isSaved,
                          );
                      // Invalidate savedMentorsProvider so Network tab updates instantly
                      ref.invalidate(savedMentorsProvider);
                      ref.invalidate(currentUserProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSaved
                                ? 'Mentor removed from saved'
                                : 'Mentor saved to Network',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved
                        ? AntigravityTheme.electricPurple
                        : Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Name ──────────────────────────────────────────
            Text(
              firstName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Online indicator ──────────────────────────────
            if (displayMentor.isOnline) ...[
              const SizedBox(height: 2),
              const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF10B981), size: 6),
                  SizedBox(width: 4),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),

            // ── Years of Experience ───────────────────────────
            if (yoeText != null && yoeText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline_rounded, size: 13, color: Colors.white38),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        yoeText,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Match Percentage Badge ────────────────────────
            if (hasMatchData && matchScore > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '🔥 $matchScore% Match',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (hasMatchData) const SizedBox(height: 4),

            // ── Match Reason (truncated) ──────────────────────
            if (hasMatchData && matchReason.isNotEmpty)
              Flexible(
                child: Text(
                  matchReason,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ── Skill tags (max 2, only when no match reason) ─
            if (!hasMatchData && displayMentor.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.start,
                children: displayMentor.tags.take(2).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AntigravityTheme.electricPurple.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        color: AntigravityTheme.electricPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
