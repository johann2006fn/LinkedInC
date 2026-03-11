import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/antigravity_theme.dart';
import '../providers/app_providers.dart';
import '../models/chat.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(userChatsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;
    
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0B14),
        body: Center(child: CircularProgressIndicator(color: AntigravityTheme.electricPurple)),
      );
    }
    
    final isMentor = currentUser.role == 'mentor';
    final headerText = isMentor ? 'NEW STUDENTS' : 'NEW MENTORS';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B14),
        elevation: 0,
        automaticallyImplyLeading: false, // Replaces dead hamburger menu
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search active chats...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text(
                'Connections',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications empty'),
                  backgroundColor: AntigravityTheme.electricPurple,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── NEW MENTORS/STUDENTS StreamBuilder ─────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('connections')
                .where('status', isEqualTo: 'accepted')
                .where(Filter.or(
                   Filter('participants', arrayContains: currentUser.id),
                   Filter('studentId', isEqualTo: currentUser.id),
                   Filter('mentorId', isEqualTo: currentUser.id),
                ))
                .snapshots(),
            builder: (context, snapshot) {
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
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        
                        // Try to determine the other user's name across various possible field formats
                        final studentName = data['studentName'] as String? ?? '';
                        final mentorName = data['mentorName'] as String? ?? '';
                        
                        String displayName = isMentor ? studentName : mentorName;
                        if (displayName.isEmpty) {
                          displayName = data['otherUserName'] as String? ?? '?';
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AntigravityTheme.electricPurple, width: 2.5),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFF2D2040),
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                displayName.split(' ').first,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
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
                final query = _searchController.text.trim().toLowerCase();
                final filteredChats = query.isEmpty
                    ? chatList
                    : chatList.where((c) => c.otherUserName.toLowerCase().contains(query)).toList();

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_outlined, size: 60, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          query.isNotEmpty 
                              ? 'No chats found matching "$query"'
                              : 'No active connections yet.\nCheck your pending requests!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 16, height: 1.4),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: filteredChats.length,
                  itemBuilder: (_, i) => _buildChatTile(context, filteredChats[i], i),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AntigravityTheme.electricPurple)),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Chat chat, int index) {
    final timeStr = _formatTime(chat.lastUpdated);
    final unread = 0; // Removed fake hardcoded dummy unread badge metric

    return InkWell(
      onTap: () => context.push('/chat/detail', extra: chat),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF2D2040),
                  child: Text(
                    chat.otherUserName.isNotEmpty
                        ? chat.otherUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
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
                      Text(
                        chat.otherUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: unread > 0 ? AntigravityTheme.electricPurple : Colors.white54,
                          fontSize: 12,
                          fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Tap to start chatting',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread > 0 ? Colors.white : Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AntigravityTheme.electricPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
