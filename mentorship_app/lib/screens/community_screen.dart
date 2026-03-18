// ignore_for_file: unnecessary_underscores
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/community_post.dart';
import '../providers/app_providers.dart';
import '../theme/antigravity_theme.dart';

final communityPostsProvider = StreamProvider<List<CommunityPost>>((ref) {
  return FirebaseFirestore.instance
      .collection('community_posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList(),
      );
});

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  void _showCreatePostDialog(
    BuildContext context,
    String currentUserId,
    String currentUserName,
  ) {
    final TextEditingController contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AntigravityTheme.midnightBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Community Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AntigravityTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  style: const TextStyle(color: AntigravityTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Share an insight, resource, or update...',
                    hintStyle: const TextStyle(
                      color: AntigravityTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;

                    final nav = Navigator.of(context);
                    await FirebaseFirestore.instance
                        .collection('community_posts')
                        .add({
                          'authorId': currentUserId,
                          'authorName': currentUserName,
                          'content': contentController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'likesCount': 0,
                        });

                    nav.pop(); // close modal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AntigravityTheme.electricPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityPostsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    final isMentor =
        currentUserAsync
            .when(data: (v) => v, loading: () => null, error: (_, __) => null)
            ?.role ==
        'mentor';
    final currentUserId =
        currentUserAsync
            .when(data: (v) => v, loading: () => null, error: (_, __) => null)
            ?.id ??
        '';
    final currentUserName =
        currentUserAsync
            .when(data: (v) => v, loading: () => null, error: (_, __) => null)
            ?.name ??
        'Mentor';

    return Scaffold(
      backgroundColor: AntigravityTheme.pureBlack,
      appBar: AppBar(
        title: const Text(
          'Community Updates',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AntigravityTheme.pureBlack,
        elevation: 0,
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'No community posts yet.\nMentors can share updates here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AntigravityTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 120,
            ),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildPostCard(posts[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
      floatingActionButton: isMentor
          ? FloatingActionButton(
              onPressed: () => _showCreatePostDialog(
                context,
                currentUserId,
                currentUserName,
              ),
              backgroundColor: AntigravityTheme.electricPurple,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final timeString = timeago.format(post.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AntigravityTheme.midnightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AntigravityTheme.midnightBlue,
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        color: AntigravityTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      timeString,
                      style: const TextStyle(
                        color: AntigravityTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: const TextStyle(
              color: AntigravityTheme.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.thumb_up_alt_outlined,
                size: 18,
                color: AntigravityTheme.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                '${post.likesCount}',
                style: TextStyle(
                  color: AntigravityTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
