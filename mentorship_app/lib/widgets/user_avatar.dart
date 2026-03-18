import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/antigravity_theme.dart';

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;
    final firstName = user.name.split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final isMentor = user.role == 'mentor';

    Widget avatar = Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AntigravityTheme.electricPurple.withValues(alpha: 0.2),
          backgroundImage: hasImage
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: hasImage
              ? null
              : Icon(
                  isMentor ? Icons.engineering_rounded : Icons.school_rounded,
                  color: AntigravityTheme.electricPurple,
                  size: radius * 1.0,
                ),
        ),
        if (user.isOnline == true)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: AntigravityTheme.pureBlack, width: 2),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
