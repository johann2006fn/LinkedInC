import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/antigravity_theme.dart';
import '../models/app_user.dart';
import '../widgets/user_avatar.dart';
import '../providers/app_providers.dart';
import '../models/message.dart';
import '../services/video_call_service.dart';
import '../utils/video_call_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../models/session.dart';
import '../services/test_data_helper.dart';

class MentorCalendarScreen extends ConsumerStatefulWidget {
  const MentorCalendarScreen({super.key});

  @override
  ConsumerState<MentorCalendarScreen> createState() =>
      _MentorCalendarScreenState();
}

class _MentorCalendarScreenState extends ConsumerState<MentorCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _viewIndex = 0; // 0=Week, 1=Month
  final List<String> _views = ['Week', 'Month'];


  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(upcomingSessionsProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B14),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: AntigravityTheme.electricPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Day/Week/Month toggle ────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1527),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: List.generate(_views.length, (i) {
                  final selected = i == _viewIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _viewIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AntigravityTheme.electricPurple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            _views[i],
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Calendar ─────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1527),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2027, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _viewIndex == 1
                  ? CalendarFormat.month
                  : CalendarFormat.week,
              eventLoader: (day) {
                final list = sessionsAsync.value ?? [];
                return list
                    .where((s) => isSameDay(s.scheduledTime.toLocal(), day))
                    .toList();
              },
              onFormatChanged: (format) {
                if (format == CalendarFormat.month) {
                  setState(() => _viewIndex = 1);
                } else if (format == CalendarFormat.week) {
                  setState(() => _viewIndex = 0);
                }
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                _focusedDay = focused;
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white60,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Colors.white60,
                ),
                headerPadding: const EdgeInsets.only(bottom: 8),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white54, fontSize: 12),
                weekendStyle: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(color: Colors.white70),
                weekendTextStyle: const TextStyle(color: Colors.white70),
                todayDecoration: BoxDecoration(
                  color: AntigravityTheme.electricPurple,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AntigravityTheme.electricPurple.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AntigravityTheme.electricPurple,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Selected Date label ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isSameDay(_selectedDay, DateTime.now())
                    ? "Today's Sessions"
                    : DateFormat('MMM d, yyyy').format(_selectedDay),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Session list ─────────────────────────────────
          Expanded(
            child: sessionsAsync.when(
              data: (list) {
                final filteredList = list
                    .where((s) => isSameDay(s.scheduledTime.toLocal(), _selectedDay))
                    .toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy_outlined,
                          size: 60,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No scheduled sessions for this date.',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  itemCount: filteredList.length,
                  itemBuilder: (_, i) => _buildSessionCard(
                    filteredList[i],
                    currentUser?.name ?? 'User',
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AntigravityTheme.electricPurple,
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, String currentUserName) {
    String fmtTime(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final a = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $a';
    }

    final start = session.scheduledTime.toLocal();
    final end = start.add(const Duration(minutes: 30));
    final timeRange = '${fmtTime(start)} - ${fmtTime(end)}';

    final canJoin = isJoinWindowOpen(sessionStart: start);
    final isTodayCard = isSameDay(start, DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTodayCard 
              ? AntigravityTheme.electricPurple.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AntigravityTheme.electricPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          color: AntigravityTheme.electricPurple,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.topic,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: Colors.white38),
                              const SizedBox(width: 6),
                              Text(
                                'with ${session.studentName}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
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
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.white54),
                          const SizedBox(width: 6),
                          Text(
                            timeRange,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canJoin
                            ? () {
                                final service = VideoCallService();
                                service.launchMeeting(
                                  chatId: session.chatId,
                                  userName: currentUserName,
                                  topic: session.topic,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canJoin 
                              ? AntigravityTheme.electricPurple 
                              : Colors.white.withValues(alpha: 0.05),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white24,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canJoin ? Icons.videocam_rounded : Icons.lock_clock_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              canJoin ? 'Join Call' : 'Locked',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
