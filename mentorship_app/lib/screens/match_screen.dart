import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/matchmaking_service.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  List<AppUser> _matches = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runMatchmaking();
  }

  Future<void> _runMatchmaking() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _matches = [];
    });

    try {
      final userProfile = await ref
          .read(authServiceProvider)
          .getCurrentUserProfile();
      if (userProfile == null) throw Exception('User profile not found.');

      final service = MatchmakingService();
      final results = await service.getDailyMatches();
      setState(() => _matches = results);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'AI Mentor Matches',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _runMatchmaking,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Re-run matching',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _matches.isEmpty
          ? _buildEmptyState()
          : _buildMatchList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gemini is finding your\nbest matches…',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes a few seconds',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _runMatchmaking,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No mentors found in your college yet.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final mentor = _matches[index];
        return _buildMatchCard(mentor, index + 1);
      },
    );
  }

  Widget _buildMatchCard(AppUser mentor, int rank) {
    final score = mentor.matchScore;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.15),
          width: rank == 1 ? 2 : 1,
        ),
        boxShadow: rank == 1
            ? [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rank == 1
                    ? const Color(0xFF6C63FF)
                    : Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: rank == 1 ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            UserAvatar(user: mentor, radius: 26),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mentor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      if (rank == 1) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
                        const Text(
                          ' Best Match',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (mentor.subtitle != null)
                    Text(
                      mentor.subtitle!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: mentor.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6C63FF,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Score
            Column(
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  'match',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
