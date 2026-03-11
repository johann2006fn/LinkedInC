import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../theme/antigravity_theme.dart';
import '../models/session.dart';
import '../models/connection.dart';
import '../models/app_user.dart';

class MentorDashboardScreen extends ConsumerStatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  ConsumerState<MentorDashboardScreen> createState() => _MentorDashboardScreenState();
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

    final isAcceptingStream = currentUser.whenOrNull(data: (u) => u?.acceptingMentees) ?? false;
    final isAccepting = _localAccepting ?? isAcceptingStream;

    final mentorName = currentUser.when(
      data: (u) => u?.name ?? 'Mentor',
      loading: () => '...',
      error: (_, __) => 'Mentor',
    );
    final uid = currentUser.whenOrNull(data: (u) => u?.id) ?? '';
    
    // Log the UID to the terminal for easy copying!
    if (uid.isNotEmpty) {
      print('====================================');
      print('YOUR MENTOR UID IS: $uid');
      print('====================================');
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
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'MentorHub',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Text('Accepting', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                    activeColor: Colors.white,
                    activeTrackColor: AntigravityTheme.electricPurple,
                    inactiveTrackColor: Colors.white24,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Stats Row ──────────────────────────────────
              Row(
                children: [
                  _buildStatCard('TOTAL SESSIONS', totalSessions.when(
                    data: (count) => count.toString(),
                    loading: () => '—',
                    error: (_, __) => '—',
                  )),
                  const SizedBox(width: 14),
                  _buildStatCard('STUDENTS', studentsCount.when(
                    data: (count) => count.toString(),
                    loading: () => '—',
                    error: (_, __) => '—',
                  )),
                ],
              ),
              const SizedBox(height: 28),

              // ── Upcoming Sessions ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Upcoming Sessions',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => context.go('/calendar'),
                    child: const Text('View Calendar',
                        style: TextStyle(color: AntigravityTheme.electricPurple, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              upcomingSessions.when(
                data: (sessions) => sessions.isEmpty
                    ? _buildEmptyState('No upcoming sessions')
                    : SizedBox(
                        height: 175,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: sessions.length,
                          itemBuilder: (_, i) => _buildSessionCard(sessions[i]),
                        ),
                      ),
                loading: () => const SizedBox(height: 175, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _buildEmptyState('Could not load sessions'),
              ),
              const SizedBox(height: 28),

              // ── Pending Requests ───────────────────────────
              const Text('Pending Requests',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              pendingRequests.when(
                data: (requests) => requests.isEmpty
                    ? _buildEmptyState('No pending requests')
                    : Column(
                        children: requests.map((req) => _buildRequestCard(req)).toList(),
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

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1527),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AntigravityTheme.electricPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    final isToday = session.scheduledTime.day == DateTime.now().day;
    final timeLabel = isToday
        ? 'Today, ${_fmtTime(session.scheduledTime)}'
        : _fmtDate(session.scheduledTime);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.topic,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(timeLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text('Student: ${session.studentName}',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRequestCard(MentorshipConnection req) {
    final isProcessing = _processingRequests.contains(req.id);
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(req.studentId).snapshots(),
      builder: (context, snapshot) {
        final menteeData = snapshot.data?.data() as Map<String, dynamic>?;
        final mentee = menteeData != null ? AppUser.fromMap(menteeData, snapshot.data!.id) : null;
        
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
            onTap: mentee == null ? null : () => _showMenteeDetails(context, req, mentee),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF2D2040),
                    backgroundImage: mentee?.profileImageUrl != null 
                        ? NetworkImage(mentee!.profileImageUrl!) 
                        : null,
                    child: mentee?.profileImageUrl == null
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
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
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text(
                          displaySubtitle,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Decline
                  GestureDetector(
                    onTap: isProcessing ? null : () => _handleRequest(req, 'declined'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2040),
                        shape: BoxShape.circle,
                      ),
                      child: isProcessing
                          ? const Padding(padding: EdgeInsets.all(9), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                          : const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accept
                  GestureDetector(
                    onTap: isProcessing ? null : () => _handleRequest(req, 'accepted'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF9B59F5)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: isProcessing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Accept →',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

  void _showMenteeDetails(BuildContext context, MentorshipConnection req, AppUser mentee) {
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
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF2D2040),
                  backgroundImage: mentee.profileImageUrl != null 
                      ? NetworkImage(mentee.profileImageUrl!) 
                      : null,
                  child: mentee.profileImageUrl == null
                      ? Text(
                          mentee.name.isNotEmpty ? mentee.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentee.name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mentee.year ?? 'Mentee',
                        style: const TextStyle(color: AntigravityTheme.electricPurple, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'BIO',
              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              mentee.bio ?? 'No bio provided.',
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            const Text(
              'INTENTIONS & TAGS',
              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mentee.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2040),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              )).toList(),
            ),
            if (mentee.tags.isEmpty)
              const Text('No tags provided.', style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9B59F5)]),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('ACCEPT REQUEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      child: Text(msg, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 14)),
    );
  }

  void _handleRequest(MentorshipConnection req, String status) async {
    if (_processingRequests.contains(req.id)) return;
    setState(() => _processingRequests.add(req.id));

    try {
      final repo = ref.read(connectionRepositoryProvider);
      if (status == 'declined') {
        await FirebaseFirestore.instance.collection('connections').doc(req.id).delete().timeout(const Duration(seconds: 10));
      } else {
        await repo.updateConnectionStatus(req.id, status);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? '✅ Request accepted!' : '❌ Request declined'),
            backgroundColor: status == 'accepted' ? const Color(0xFF10B981) : Colors.redAccent,
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
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${_fmtTime(dt)}';
  }
}
