// ignore_for_file: unnecessary_underscores
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_providers.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/notification_sheet.dart';
import '../models/session.dart';
import '../models/connection.dart';
import '../models/app_user.dart';
import '../widgets/user_avatar.dart';
import '../services/test_data_helper.dart';
import '../utils/video_call_utils.dart';
import '../services/video_call_service.dart';

class MentorDashboardScreen extends ConsumerStatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  ConsumerState<MentorDashboardScreen> createState() =>
      _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends ConsumerState<MentorDashboardScreen> {
  bool? _localAccepting;
  final Set<String> _processingRequests = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final pendingRequests = ref.watch(pendingRequestsProvider);
    final upcomingSessions = ref.watch(upcomingSessionsProvider);
    final totalSessions = ref.watch(mentorTotalSessionsProvider);
    final studentsCount = ref.watch(mentorStudentsCountProvider);

    final isAcceptingStream =
        currentUser.whenOrNull(data: (u) => u?.acceptingMentees) ?? false;
    final isAccepting = _localAccepting ?? isAcceptingStream;

    final fullName = currentUser.when(
      data: (u) => u?.name ?? 'Mentor',
      loading: () => '...',
      error: (_, __) => 'Mentor',
    );
    final firstName = fullName.split(' ').first;
    final uid = currentUser.whenOrNull(data: (u) => u?.id) ?? '';

    // Log the UID to the terminal for easy copying!
    if (uid.isNotEmpty) {
      debugPrint('====================================');
      debugPrint('YOUR MENTOR UID IS: $uid');
      debugPrint('====================================');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AntigravityTheme.electricPurple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        firstName.isNotEmpty
                            ? firstName[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $firstName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          'Mentor Dashboard',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (uid.isNotEmpty)
                    NotificationSheet.bellIcon(
                      userId: uid,
                      onPressed: () => NotificationSheet.show(context, uid),
                    ),
                  const Text(
                    'Accepting',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isAccepting,
                    onChanged: (val) {
                      setState(() => _localAccepting = val);
                      if (uid.isNotEmpty) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({'acceptingMentees': val});
                      }
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: AntigravityTheme.electricPurple,
                    inactiveTrackColor: Colors.white24,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Stats Row ──────────────────────────────────
              Row(
                children: [
                  _buildStatCard(
                    'TOTAL SESSIONS',
                    totalSessions.when(
                      data: (value) => value.toString(),
                      loading: () => '—',
                      error: (_, __) => '—',
                    ),
                    onTap: () => context.go('/calendar'),
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    'STUDENTS',
                    studentsCount.when(
                      data: (value) => value.toString(),
                      loading: () => '—',
                      error: (_, __) => '—',
                    ),
                    onTap: () => _showStudentsList(context),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              upcomingSessions.when(
                data: (sessions) {
                  final now = DateTime.now();
                  final todaySessions = sessions.where((s) {
                    final d = s.scheduledTime.toLocal();
                    return d.year == now.year && d.month == now.month && d.day == now.day;
                  }).toList();
                  
                  final futureSessions = sessions.where((s) {
                    final d = s.scheduledTime.toLocal();
                    final sessionDate = DateTime(d.year, d.month, d.day);
                    final todayDate = DateTime(now.year, now.month, now.day);
                    return sessionDate.isAfter(todayDate);
                  }).toList();

                  final currentMentorName = ref.read(currentUserProvider).value?.name ?? 'Mentor';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Today's Sessions ──────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today\'s Sessions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/calendar'),
                            child: const Text(
                              'View Calendar',
                              style: TextStyle(
                                color: AntigravityTheme.electricPurple,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      todaySessions.isEmpty
                          ? _buildEmptyState('No sessions scheduled for today')
                          : SizedBox(
                              height: 235,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: todaySessions.length,
                                itemBuilder: (_, i) => _buildSessionCard(
                                  todaySessions[i], 
                                  isTodayCard: true,
                                  currentMentorName: currentMentorName,
                                ),
                              ),
                            ),
                      const SizedBox(height: 28),

                      // ── Upcoming Sessions ──────────────────────────
                      const Text(
                        'Upcoming Sessions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      futureSessions.isEmpty
                          ? _buildEmptyState('No upcoming sessions')
                          : SizedBox(
                              height: 235,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: futureSessions.length,
                                itemBuilder: (_, i) => _buildSessionCard(
                                  futureSessions[i],
                                  currentMentorName: currentMentorName,
                                ),
                              ),
                            ),
                      const SizedBox(height: 28),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 175,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _buildEmptyState('Could not load sessions'),
              ),

              // ── Pending Requests ───────────────────────────
              const Text(
                'Pending Requests',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              pendingRequests.when(
                data: (requests) => requests.isEmpty
                    ? _buildEmptyState('No pending requests')
                    : Column(
                        children: requests
                            .map((req) => _buildRequestCard(req))
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildEmptyState('Could not load requests'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AntigravityTheme.electricPurple.withValues(alpha: 0.15),
          highlightColor: AntigravityTheme.electricPurple.withValues(alpha: 0.05),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1527),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AntigravityTheme.electricPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'View →',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStudentsList(BuildContext context) {
    final uid =
        ref.read(currentUserProvider).whenOrNull(data: (u) => u?.id) ?? '';
    if (uid.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0B14),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Students',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('connections')
                    .where('mentorId', isEqualTo: uid)
                    .where('status', isEqualTo: 'accepted')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No students yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;
                      final studentId = data['studentId'] as String? ?? '';
                      final studentName =
                          data['studentName'] as String? ?? 'Student';

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(studentId)
                            .get(),
                        builder: (context, userSnap) {
                          final user = userSnap.data?.data()
                              as Map<String, dynamic>?;
                          final name =
                              user?['name'] as String? ?? studentName;
                          final year =
                              user?['year'] as String? ?? 'Mentee';

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF2D2040),
                              child: Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              year,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Session session, {bool isTodayCard = false, required String currentMentorName}) {
    final start = session.scheduledTime.toLocal();
    final now = DateTime.now();
    final isToday = start.year == now.year && start.month == now.month && start.day == now.day;
    final timeLabel = isToday
        ? 'Today, ${_fmtTime(start)}'
        : _fmtDate(start);

    final canJoin = isJoinWindowOpen(sessionStart: start);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1527),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTodayCard 
              ? AntigravityTheme.electricPurple.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: isTodayCard ? 1.5 : 1,
        ),
        boxShadow: isTodayCard ? [
          BoxShadow(
            color: AntigravityTheme.electricPurple.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AntigravityTheme.electricPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isTodayCard ? 'TODAY' : 'UPCOMING',
                          style: const TextStyle(
                            color: AntigravityTheme.electricPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.more_horiz, color: Colors.white38, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    session.topic,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'with ${session.studentName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Colors.white70, 
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canJoin
                    ? () {
                        final service = VideoCallService();
                        service.launchMeeting(
                          chatId: session.chatId,
                          userName: currentMentorName,
                          topic: session.topic,
                        );
                      }
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canJoin ? AntigravityTheme.electricPurple : Colors.white.withValues(alpha: 0.05),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white24,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(canJoin ? Icons.videocam_rounded : Icons.lock_clock_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        canJoin ? 'Join Session' : 'Locked',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(MentorshipConnection req) {
    final isProcessing = _processingRequests.contains(req.id);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(req.studentId)
          .snapshots(),
      builder: (context, snapshot) {
        final menteeData = snapshot.data?.data() as Map<String, dynamic>?;
        final mentee = menteeData != null
            ? AppUser.fromMap(menteeData, snapshot.data!.id)
            : null;

        final displayName = mentee?.name ?? req.studentName.split(' ')[0];
        final displaySubtitle = mentee != null
            ? "${mentee.name} • ${mentee.year ?? 'Mentee'}"
            : "Pending Request";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1527),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: mentee == null
                ? null
                : () => _showMenteeDetails(context, req, mentee),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  mentee != null
                      ? UserAvatar(user: mentee, radius: 22)
                      : CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF2D2040),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.length > 18
                              ? '${displayName.substring(0, 15)}...'
                              : displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          displaySubtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Decline
                  GestureDetector(
                    onTap: isProcessing
                        ? null
                        : () => _handleRequest(req, 'declined'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2040),
                        shape: BoxShape.circle,
                      ),
                      child: isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.redAccent,
                              ),
                            )
                          : const Icon(
                              Icons.close_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accept
                  GestureDetector(
                    onTap: isProcessing
                        ? null
                        : () => _handleRequest(req, 'accepted'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9B59F5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Accept →',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMenteeDetails(
    BuildContext context,
    MentorshipConnection req,
    AppUser mentee,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0B14),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                UserAvatar(user: mentee, radius: 40),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentee.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mentee.year ?? 'Mentee',
                        style: const TextStyle(
                          color: AntigravityTheme.electricPurple,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'BIO',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mentee.bio ?? 'No bio provided.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'INTENTIONS & TAGS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mentee.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2040),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (mentee.tags.isEmpty)
              const Text(
                'No tags provided.',
                style: TextStyle(
                  color: Colors.white24,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleRequest(req, 'declined');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'DECLINE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9B59F5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleRequest(req, 'accepted');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ACCEPT REQUEST',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1527),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white38, fontSize: 14),
      ),
    );
  }

  void _handleRequest(MentorshipConnection req, String status) async {
    if (_processingRequests.contains(req.id)) return;

    if (status == 'declined') {
      // Show decline reason dialog
      final reason = await _showDeclineReasonDialog();
      if (reason == null) return; // User cancelled
      await _processDecline(req, reason);
    } else if (status == 'accepted') {
      await _processAccept(req);
    }
  }

  Future<String?> _showDeclineReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Decline Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for declining this request:',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g., Currently at full capacity...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AntigravityTheme.electricPurple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              Navigator.pop(context, reason.isEmpty ? 'No reason provided' : reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _processDecline(MentorshipConnection req, String reason) async {
    setState(() => _processingRequests.add(req.id));
    try {
      final mentorName = ref.read(currentUserProvider).value?.name ?? 'Mentor';

      // 1. Delete the connection document
      await FirebaseFirestore.instance
          .collection('connections')
          .doc(req.id)
          .delete()
          .timeout(const Duration(seconds: 10));

      // 2. Send a notification to the mentee with the decline reason
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': req.studentId,
        'title': 'Request Declined',
        'message': '$mentorName declined your request: $reason',
        'type': 'request_declined',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'declineReason': reason,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Request declined'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingRequests.remove(req.id));
    }
  }

  Future<void> _processAccept(MentorshipConnection req) async {
    setState(() => _processingRequests.add(req.id));
    try {
      final repo = ref.read(connectionRepositoryProvider);
      await repo.acceptMentorshipRequest(
        req.id,
        req.studentId,
        req.mentorId,
        req.mentorName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Request accepted!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingRequests.remove(req.id));
    }
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final a = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $a';
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${_fmtTime(dt)}';
  }
}
