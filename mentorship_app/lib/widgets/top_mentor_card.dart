import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TopMentorCard extends StatelessWidget {
  final String name;
  final String role;
  final String exp;
  final String mentees;

  const TopMentorCard({
    super.key,
    required this.name,
    required this.role,
    required this.exp,
    required this.mentees,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.background,
            child: Icon(Icons.person, color: AppTheme.textSecondary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            role.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    exp,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Text(
                    'Exp',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                ],
              ),
              Container(
                height: 24,
                width: 1,
                color: Colors.grey.withOpacity(0.3),
              ),
              Column(
                children: [
                  Text(
                    mentees,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Text(
                    'Mentees',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'PROFILE',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
