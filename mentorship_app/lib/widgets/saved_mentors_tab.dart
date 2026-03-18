import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/mentor_card.dart';

class SavedMentorsTab extends ConsumerWidget {
  const SavedMentorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedMentorsAsync = ref.watch(savedMentorsProvider);

    return savedMentorsAsync.when(
      data: (mentors) {
        if (mentors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No saved mentors yet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bookmark mentors to find them here easily',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: mentors.length,
          itemBuilder: (context, index) {
            final mentor = mentors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MentorCard(mentor: mentor),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Error loading saved mentors: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
