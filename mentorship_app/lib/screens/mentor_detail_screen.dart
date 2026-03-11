import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../theme/antigravity_theme.dart';
import '../models/app_user.dart';
import '../models/connection.dart';
import '../providers/app_providers.dart';

class MentorDetailScreen extends ConsumerStatefulWidget {
  final AppUser mentor;

  const MentorDetailScreen({super.key, required this.mentor});

  @override
  ConsumerState<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends ConsumerState<MentorDetailScreen> {
  bool _isLoading = false;
  bool _requestSent = false;
  bool _isLoadingState = true;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  Future<void> _checkExistingConnection() async {
    try {
      final student = ref.read(currentUserProvider).value;
      if (student == null) {
        if (mounted) setState(() => _isLoadingState = false);
        return;
      }
      final hasPending = await ref.read(connectionRepositoryProvider).hasPendingConnection(student.id, widget.mentor.id);
      if (mounted) {
        setState(() {
          _requestSent = hasPending;
          _isLoadingState = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingState = false);
    }
  }

  Future<void> _requestMentorship() async {
    if (_isLoading || _requestSent) return;
    setState(() => _isLoading = true);

    try {
      final student = ref.read(currentUserProvider).value;
      if (student == null) throw Exception('Not logged in');

      await ref.read(connectionRepositoryProvider).requestMentorship(
        MentorshipConnection(
          id: '',
          studentId: student.id,
          studentName: student.name,
          mentorId: widget.mentor.id,
          mentorName: widget.mentor.name,
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => _requestSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Request sent! Waiting for mentor approval.', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1527),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network timeout. Please check your connection and try again.'),
          backgroundColor: Colors.redAccent,
        )
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        )
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = (widget.mentor.tags as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Hero-like image background ──────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2D2040), Colors.black],
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF1A1527),
                        backgroundImage: widget.mentor.profileImageUrl != null && widget.mentor.profileImageUrl!.isNotEmpty
                            ? NetworkImage(widget.mentor.profileImageUrl!)
                            : null,
                        child: widget.mentor.profileImageUrl == null || widget.mentor.profileImageUrl!.isEmpty
                            ? Text(
                                widget.mentor.name.isNotEmpty ? widget.mentor.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.mentor.name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.mentor.subtitle ?? 'Expert Mentor',
                      style: const TextStyle(color: AntigravityTheme.electricPurple, fontSize: 16)),
                  const SizedBox(height: 32),

                  // ── About Section ────────────────────────
                  const Text('About Me',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    widget.mentor.bio ?? 'Passionate mentor dedicated to helping students navigate their career paths and master technical skills in software engineering and product design.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  // ── Expertise Section ────────────────────
                  const Text('Expertise',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1527),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Text(t,
                                  style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 100), // Spacer for sticky footer
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_isLoading || _requestSent || _isLoadingState) ? null : _requestMentorship,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_requestSent || _isLoadingState) ? const Color(0xFF1E293B) : AntigravityTheme.electricPurple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: (_requestSent || _isLoadingState) ? const Color(0xFF1E293B) : Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: (_requestSent || _isLoadingState) ? 0 : 8,
              shadowColor: AntigravityTheme.electricPurple.withValues(alpha: 0.5),
            ),
            child: (_isLoading || _isLoadingState)
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _requestSent ? 'REQUEST PENDING' : 'REQUEST MENTORSHIP',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2,
                      color: _requestSent ? Colors.white54 : Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
}
}
