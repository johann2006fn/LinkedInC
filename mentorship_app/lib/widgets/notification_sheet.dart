import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../theme/antigravity_theme.dart';

/// Reusable notification sheet that can be called from any screen.
/// Uses DraggableScrollableSheet for swipe-to-full-screen behavior.
class NotificationSheet {
  static void show(BuildContext context, String currentUserId) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1A29),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ── Drag handle ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // ── Header row ──────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _markAllRead(currentUserId),
                          child: const Text(
                            'Mark all read',
                            style: TextStyle(
                              color: AntigravityTheme.electricPurple,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Notification list ───────────────────────
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .where('userId', isEqualTo: currentUserId)
                          .orderBy('timestamp', descending: true)
                          .limit(50)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AntigravityTheme.electricPurple,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmpty();
                        }

                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final notif = AppNotification.fromMap(
                              docs[index].data() as Map<String, dynamic>,
                              docs[index].id,
                            );

                            final (IconData iconData, Color iconColor) =
                                _iconForType(notif.type);
                            final timeAgo = _formatTimeAgo(notif.timestamp);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: notif.isRead
                                    ? Colors.transparent
                                    : AntigravityTheme.electricPurple
                                        .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      iconColor.withValues(alpha: 0.15),
                                  child: Icon(iconData,
                                      color: iconColor, size: 20),
                                ),
                                title: Text(
                                  notif.title,
                                  style: TextStyle(
                                    color: notif.isRead
                                        ? Colors.white70
                                        : Colors.white,
                                    fontWeight: notif.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    notif.message,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      timeAgo,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (!notif.isRead) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color:
                                              AntigravityTheme.electricPurple,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  if (!notif.isRead) {
                                    FirebaseFirestore.instance
                                        .collection('notifications')
                                        .doc(notif.id)
                                        .update({'isRead': true});
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static (IconData, Color) _iconForType(String type) {
    return switch (type) {
      'request_sent' => (Icons.send, Colors.blueAccent),
      'request_received' =>
        (Icons.person_add, AntigravityTheme.electricPurple),
      'accepted' || 'request_accepted' => (Icons.check_circle, const Color(0xFF10B981)),
      'request_declined' => (Icons.cancel_outlined, Colors.redAccent),
      'session_reminder' => (Icons.calendar_today, Colors.orangeAccent),
      'session_confirmed' => (Icons.event_available, const Color(0xFF10B981)),
      'endorsement' => (Icons.military_tech, Colors.amberAccent),
      _ => (Icons.info_outline, Colors.white54),
    };
  }

  static String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  static Future<void> _markAllRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final unread = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {
      // Silently handle — non-critical
    }
  }

  static Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1527),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: AntigravityTheme.electricPurple,
              size: 28,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "We'll notify you when you have new activity.",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a notification bell icon with an unread badge dot.
  /// Use this in AppBar actions for a consistent look.
  static Widget bellIcon({
    required String userId,
    required VoidCallback onPressed,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: 26,
          ),
          onPressed: onPressed,
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AntigravityTheme.electricPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
