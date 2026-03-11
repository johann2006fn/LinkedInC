import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/antigravity_theme.dart';
import 'package:go_router/go_router.dart';

class MentorCard extends StatelessWidget {
  final AppUser mentor;

  const MentorCard({super.key, required this.mentor});

  @override
  Widget build(BuildContext context) {
    // Only display max 2 skills
    final displaySkills = mentor.tags.take(2).toList();
    final firstName = mentor.name.split(' ').first;

    return GestureDetector(
      onTap: () => context.push('/mentor-detail', extra: mentor),
      child: Container(
        decoration: BoxDecoration(
          color: AntigravityTheme.softBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AntigravityTheme.softBlue.withOpacity(0.15),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AntigravityTheme.electricPurple.withOpacity(0.2),
              backgroundImage: mentor.profileImageUrl != null
                  ? NetworkImage(mentor.profileImageUrl!)
                  : null,
              child: mentor.profileImageUrl == null
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AntigravityTheme.electricPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            if (displaySkills.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: displaySkills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AntigravityTheme.electricPurple.withOpacity(0.15),
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
