import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../models/connection.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pendingRequests = ref.watch(pendingRequestsProvider);
    final activeMentors = ref.watch(activeMentorsProvider);
    final sessions = ref.watch(upcomingSessionsProvider);

    final pendingCount = pendingRequests.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final activeCount = activeMentors.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Mentors', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              radius: 16,
              child: Text(
                '${pendingCount + activeCount}',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryStats(pendingCount, activeCount),
            const SizedBox(height: 16),
            _buildTabSelector(pendingCount, activeCount),
            const SizedBox(height: 24),

            // PENDING MENTORS
            const Text(
              'PENDING MENTORS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            pendingRequests.when(
              data: (list) {
                if (list.isEmpty) return _buildEmptyState('No pending requests');
                return Column(
                  children: list.map((conn) {
                    final daysAgo = DateTime.now().difference(conn.createdAt).inDays;
                    final timeAgo = daysAgo == 0 ? 'TODAY' : daysAgo < 7 ? '${daysAgo}D AGO' : '${(daysAgo / 7).floor()}W AGO';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPendingMentorCard(
                        name: conn.mentorName,
                        timeAgo: timeAgo,
                        subtitle: conn.mentorSubtitle,
                        tags: conn.mentorTags,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmptyState('Could not load requests'),
            ),

            const SizedBox(height: 32),
            const Text(
              'MY ACTIVE MENTORS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            activeMentors.when(
              data: (list) {
                if (list.isEmpty) return _buildEmptyState('No active mentors yet');
                return Column(
                  children: list.map((conn) {
                    // Find next session for this mentor
                    final nextSession = sessions.when(
                      data: (sessionList) {
                        final mentorSessions = sessionList.where((s) => s.mentorId == conn.mentorId).toList();
                        if (mentorSessions.isEmpty) return 'No session scheduled';
                        return DateFormat('EEEE, h:mm a').format(mentorSessions.first.scheduledTime);
                      },
                      loading: () => '...',
                      error: (_, __) => 'N/A',
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActiveMentorCard(
                        name: conn.mentorName,
                        isActive: true,
                        nextSession: nextSession,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmptyState('Could not load mentors'),
            ),

            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View history ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(int pendingCount, int activeCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(pendingCount.toString(), 'REQUESTS\nSENT'),
          Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2)),
          _buildStatItem(activeCount.toString(), 'ACTIVE\nMENTORS', isBlue: true),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {bool isBlue = false}) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isBlue ? AppTheme.primaryBlue : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(int pendingCount, int activeCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppTheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTabIndex == 0
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Requested ($pendingCount)',
                  style: TextStyle(
                    fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTabIndex == 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppTheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTabIndex == 1
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Accepted ($activeCount)',
                  style: TextStyle(
                    fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTabIndex == 1 ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingMentorCard({
    required String name,
    required String timeAgo,
    required String subtitle,
    required List<String> tags,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.background,
                child: Icon(Icons.person, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: tags.map((tag) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Withdraw',
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMentorCard({
    required String name,
    required bool isActive,
    required String nextSession,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        const Text('Active', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
                },
                icon: const Icon(Icons.more_horiz, color: AppTheme.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEXT SESSION',
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(nextSession, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppTheme.textPrimary),
                  label: const Text('Message', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.primaryBlue),
                  label: const Text('Goals', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
