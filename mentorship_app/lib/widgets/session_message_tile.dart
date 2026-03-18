import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../services/video_call_service.dart';
import '../utils/video_call_utils.dart';
import './feedback_bottom_sheet.dart';
import './post_session_feedback_sheet.dart';
import '../models/session.dart';
import '../repositories/session_repository.dart';
import '../theme/antigravity_theme.dart';


class SessionMessageTile extends StatefulWidget {
  final Message message;
  final bool isCurrentUserMentor;
  final String currentUserName;
  final Function(DateTime newTime)? onReschedule;
  final Function()? onConfirm;
  final Function()? onCallStarted;
  final Function(int durationMins)? onCallEnded;
  final String currentUserId;

  const SessionMessageTile({
    super.key,
    required this.message,
    required this.isCurrentUserMentor,
    required this.currentUserName,
    required this.currentUserId,
    this.onReschedule,
    this.onConfirm,
    this.onCallStarted,
    this.onCallEnded,
  });

  @override
  State<SessionMessageTile> createState() => _SessionMessageTileState();
}

class _SessionMessageTileState extends State<SessionMessageTile>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  bool _isCallActive = false;
  bool _showAiBrief = false;
  late AnimationController _pulseController;
  final VideoCallService _videoCallService = VideoCallService();
  final SessionRepository _sessionRepository = SessionRepository();
  StreamSubscription<Session?>? _sessionSubscription;
  Session? _currentSession;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _checkCallStatus();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkCallStatus();
    });

    _initPresenceSubscription();
  }

  void _initPresenceSubscription() {
    final sessionId = widget.message.metadata?['sessionId'] as String?;
    if (sessionId != null) {
      _sessionSubscription = _sessionRepository
          .getSessionStream(sessionId)
          .listen((session) {
            if (mounted) {
              setState(() {
                _currentSession = session;
              });
            }
          });
    }
  }

  void _checkCallStatus() {
    final status = widget.message.sessionStatus;
    if (status != 'confirmed' && status != 'ongoing') {
      if (_isCallActive) setState(() => _isCallActive = false);
      return;
    }

    final proposedTime = widget.message.proposedTime;
    if (proposedTime == null) return;

    final isActive = isJoinWindowOpen(sessionStart: proposedTime);

    if (_isCallActive != isActive) {
      if (mounted) {
        setState(() {
          _isCallActive = isActive;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _sessionSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('EEE, MMM d • h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.message.sessionStatus ?? 'proposed';
    final topic = widget.message.sessionTopic ?? 'Mentorship Session';
    final time = widget.message.proposedTime;
    final aiBrief = widget.message.aiBrief;
    final isSessionActive = status == 'confirmed' || status == 'ongoing';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isCallActive 
              ? AntigravityTheme.neonGreen.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: _isCallActive ? 2 : 1,
        ),
        boxShadow: [
          if (_isCallActive)
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AntigravityTheme.electricPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SESSION',
                        style: TextStyle(
                          color: AntigravityTheme.electricPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    if (isSessionActive && time != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isCallActive 
                              ? AntigravityTheme.neonGreen.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isCallActive 
                                ? AntigravityTheme.neonGreen.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                             Icon(
                               Icons.fiber_manual_record,
                               size: 10,
                               color: _isCallActive ? const Color(0xFF10B981) : Colors.grey[600],
                             ),
                            const SizedBox(width: 8),
                            Text(
                              _isCallActive ? 'JOIN NOW' : 'LOCKED',
                              style: TextStyle(
                                color: _isCallActive ? const Color(0xFF10B981) : Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  time != null ? _formatDateTime(time) : 'TBD',
                ),
                const SizedBox(height: 20),

                if (status == 'proposed' || status == 'rescheduled') ...[
                  if (widget.message.senderId != widget.currentUserId) ...[
                    if (aiBrief != null && aiBrief.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => setState(() => _showAiBrief = !_showAiBrief),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _showAiBrief ? Icons.lightbulb : Icons.lightbulb_outline,
                                size: 16,
                                color: Colors.amber[400],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _showAiBrief ? 'Hide AI Brief' : 'View AI Brief',
                                style: TextStyle(
                                  color: Colors.amber[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showAiBrief) _buildAiBriefBox(aiBrief),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Reschedule',
                            Colors.white38,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: time ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null && context.mounted) {
                                final timePicked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(time ?? DateTime.now()),
                                );
                                if (timePicked != null && context.mounted) {
                                  widget.onReschedule?.call(
                                    DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      timePicked.hour,
                                      timePicked.minute,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Confirm',
                            const Color(0xFF7C3AED),
                            isPrimary: true,
                            onTap: widget.onConfirm,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildStatusFooter('Waiting for confirmation...'),
                  ],
                ] else if (isSessionActive) ...[
                  _buildJoinOrExpire(time),
                ] else if (status == 'completed') ...[
                  _buildStatusFooter('Mentorship Session Completed'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAiBriefBox(String brief) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Text(
        brief,
        style: TextStyle(
          color: Colors.amber[200],
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color, {
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFooter(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildJoinOrExpire(DateTime? time) {
    if (time == null) return const SizedBox.shrink();

    final isExpired = DateTime.now().isAfter(
      time.add(const Duration(hours: 1)),
    );

    if (isExpired) {
      return Column(
        children: [
          _buildStatusFooter('Session Ended'),
          if (!widget.isCurrentUserMentor) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                'Rate Mentor',
                const Color(0xFF7C3AED),
                isPrimary: false,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => FeedbackBottomSheet(
                      mentorId: widget.message.mentorId ?? '',
                      menteeId: widget.message.menteeId ?? '',
                      sessionId: widget.message.id,
                      chatId: widget.message.chatId,
                      messageId: widget.message.id,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    }

    return _buildJoinButton();
  }

  Widget _buildJoinButton() {
    if (_isCallActive) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return InkWell(
            onTap: () async {
                final bool? confirmJoin = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Join Video Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: const Text(
                      'Are you ready to start your mentorship session? Both participants will be notified when you join.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Later', style: TextStyle(color: Colors.white38)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('Join Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmJoin != true) return;

                widget.onCallStarted?.call();
                final startTime = DateTime.now();
                final sessionId = widget.message.metadata?['sessionId'] as String?;

                if (sessionId != null) {
                  await _sessionRepository.updatePresence(sessionId, widget.currentUserId, true);
                }

                await _videoCallService.launchMeeting(
                  chatId: widget.message.chatId,
                  userName: widget.currentUserName,
                  topic: widget.message.sessionTopic ?? "Mentorship Session",
                  onJoined: () {
                    developer.log("Participant joined visually in Jitsi");
                  },
                  onTerminated: () async {
                    if (sessionId != null) {
                      await _sessionRepository.updatePresence(sessionId, widget.currentUserId, false);
                      
                      final endTime = DateTime.now();
                      final duration = endTime.difference(startTime).inMinutes;
                      
                      // Log call immediately
                      await _sessionRepository.completeSession(sessionId, duration);
                      
                      if (mounted) {
                        widget.onCallEnded?.call(duration);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Session completed ($duration mins)'),
                            backgroundColor: const Color(0xFF7C3AED),
                          ),
                        );
                      }
                    }
                  },
                );

                if (!widget.isCurrentUserMentor && context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PostSessionFeedbackSheet(
                      mentorId: widget.message.mentorId ?? '',
                    ),
                  );
                }
              },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.8 + (_pulseController.value * 0.2)),
                    const Color(0xFF059669).withValues(alpha: 0.8 + (_pulseController.value * 0.2)),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4 * _pulseController.value),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentSession != null) ...[
                    _buildPresenceStatus(),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _isCallActive ? 'Join Live Session' : 'Re-join Session',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      final timeStr = widget.message.proposedTime != null
          ? DateFormat('h:mm a').format(widget.message.proposedTime!.toLocal())
          : '';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
            const SizedBox(width: 10),
            Text(
              'Join Call (Locked until ${timeStr.isEmpty ? 'start' : timeStr})',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }


  Widget _buildPresenceStatus() {
    final session = _currentSession;
    if (session == null) return const SizedBox.shrink();

    final otherId = widget.isCurrentUserMentor ? session.studentId : session.mentorId;
    final otherName = widget.isCurrentUserMentor ? session.studentName : session.mentorName;
    final isOtherOnline = session.presence[otherId] ?? false;
    final isMeOnline = session.presence[widget.currentUserId] ?? false;

    String statusText;
    if (isOtherOnline && isMeOnline) {
      statusText = 'Both are in the call';
    } else if (isOtherOnline) {
      statusText = '$otherName is waiting for you';
    } else if (isMeOnline) {
      statusText = 'Waiting for $otherName to join...';
    } else {
      statusText = 'Session is live! Click to join';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOtherOnline 
              ? AntigravityTheme.neonGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPresenceIndicator(isOtherOnline),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                color: isOtherOnline ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceIndicator(bool isOnline) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isOnline ? AntigravityTheme.neonGreen : Colors.amber,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AntigravityTheme.neonGreen : Colors.amber).withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

}
