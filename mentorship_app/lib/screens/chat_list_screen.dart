import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/antigravity_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/notification_sheet.dart';
import '../models/chat.dart';
import '../models/app_user.dart';
import '../widgets/user_avatar.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(userChatsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0B14),
        body: Center(
          child: CircularProgressIndicator(
            color: AntigravityTheme.electricPurple,
          ),
        ),
      );
    }

    final isMentor = currentUser.role == 'mentor';
    final headerText = isMentor ? 'NEW STUDENTS' : 'NEW MENTORS';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B14),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Connections',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          NotificationSheet.bellIcon(
            userId: currentUser.id,
            onPressed: () => NotificationSheet.show(context, currentUser.id),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('connections')
                .where('status', isEqualTo: 'accepted')
                .where(isMentor ? 'mentorId' : 'studentId', isEqualTo: currentUser.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error loading connections: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                );
              }
              if (!snapshot.hasData) return const SizedBox.shrink();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      headerText,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  Container(
                    height: 110,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final otherUserId = isMentor
                            ? (data['studentId'] as String? ?? '')
                            : (data['mentorId'] as String? ?? '');

                        return Consumer(
                          builder: (context, ref, child) {
                            final otherUserAsync = ref.watch(otherUserProfileProvider(otherUserId));

                            return otherUserAsync.when(
                              data: (user) {
                                final displayName = user?.name ?? 
                                    (isMentor ? (data['studentName'] as String? ?? 'Student') : (data['mentorName'] as String? ?? 'Mentor'));
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: GestureDetector(
                                    onTap: () async {
                                      try {
                                        if (otherUserId.isEmpty) return;

                                        String? chatId = data['chatId'] as String?;
                                        if (chatId == null || chatId.isEmpty) {
                                          chatId = await ref
                                              .read(chatRepositoryProvider)
                                              .getOrCreateChatId(
                                                currentUser.id,
                                                otherUserId,
                                              );
                                        }

                                        if (context.mounted) {
                                          context.push('/chat/$chatId');
                                        }
                                      } catch (e) {
                                        debugPrint("NAVIGATION_DEBUG: $e");
                                      }
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 62,
                                          height: 62,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AntigravityTheme.electricPurple.withValues(alpha: 0.4),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AntigravityTheme.electricPurple.withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                spreadRadius: -2,
                                              ),
                                            ],
                                          ),
                                          child: user != null 
                                              ? UserAvatar(user: user, radius: 28)
                                              : CircleAvatar(
                                                  backgroundColor: AntigravityTheme.midnightBlue.withValues(alpha: 0.8),
                                                  child: Icon(
                                                    isMentor ? Icons.school_rounded : Icons.engineering_rounded,
                                                    color: Colors.white,
                                                    size: 26,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          displayName.split(' ').first,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: 58,
                                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                ),
                              ),
                              error: (e, _) => const SizedBox.shrink(),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // ── ACTIVE CHATS ────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'ACTIVE CHATS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Expanded(
            child: chats.when(
              data: (chatList) {
                if (chatList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.forum_outlined,
                          size: 60,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No active connections yet.\nCheck your pending requests!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: chatList.length,
                  itemBuilder: (_, i) =>
                      _buildChatTile(context, chatList[i], i),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AntigravityTheme.electricPurple,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Chat chat, int index) {
    final timeStr = _formatTime(chat.lastUpdated);

    // ── FIX: Use StreamBuilder with otherUserProfileProvider to avoid
    // the "Unknown" / hat-icon flash caused by FutureBuilder re-firing.
    return Consumer(
      builder: (context, ref, child) {
        final otherUserAsync = ref.watch(otherUserProfileProvider(chat.otherUserId));

        return otherUserAsync.when(
          data: (otherUser) => _buildChatTileContent(
            context: context,
            chat: chat,
            otherUser: otherUser,
            displayName: otherUser?.name ?? (chat.otherUserName.isNotEmpty ? chat.otherUserName : 'User'),
            timeStr: timeStr,
          ),
          loading: () => _buildChatTileContent(
            context: context,
            chat: chat,
            otherUser: null,
            // Use cached otherUserName while loading to prevent flash
            displayName: chat.otherUserName.isNotEmpty ? chat.otherUserName : 'Loading...',
            timeStr: timeStr,
            isLoading: true,
          ),
          error: (_, _) => _buildChatTileContent(
            context: context,
            chat: chat,
            otherUser: null,
            displayName: chat.otherUserName.isNotEmpty ? chat.otherUserName : 'User',
            timeStr: timeStr,
          ),
        );
      },
    );
  }

  Widget _buildChatTileContent({
    required BuildContext context,
    required Chat chat,
    required AppUser? otherUser,
    required String displayName,
    required String timeStr,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: () {
        try {
          context.push('/chat/${chat.id}', extra: chat);
        } catch (e) {
          debugPrint("NAVIGATION_DEBUG: $e");
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AntigravityTheme.electricPurple.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: otherUser != null
                  ? UserAvatar(user: otherUser, radius: 28)
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF2D2040),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AntigravityTheme.electricPurple,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white54,
                              size: 22,
                            ),
                    ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage.isNotEmpty
                        ? chat.lastMessage
                        : 'Tap to start chatting',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(time); // "2:30 PM"
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time); // "Oct 12"
    }
  }
}
