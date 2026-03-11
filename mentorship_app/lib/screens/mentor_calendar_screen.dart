import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/antigravity_theme.dart';
import '../providers/app_providers.dart';
import '../models/session.dart';

class MentorCalendarScreen extends ConsumerStatefulWidget {
  const MentorCalendarScreen({super.key});

  @override
  ConsumerState<MentorCalendarScreen> createState() => _MentorCalendarScreenState();
}

class _MentorCalendarScreenState extends ConsumerState<MentorCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _viewIndex = 0; // 0=Week, 1=Month
  final List<String> _views = ['Week', 'Month'];

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(upcomingSessionsProvider);

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
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
          ),
        ),
        title: const Text('Schedule',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.white), 
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
              }),
        ],
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
                          color: selected ? AntigravityTheme.electricPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(_views[i],
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white54,
                                fontWeight:
                                    selected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              )),
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
              calendarFormat: _viewIndex == 1 ? CalendarFormat.month : CalendarFormat.week,
              eventLoader: (day) {
                final list = sessions.value ?? [];
                return list.where((s) => isSameDay(s.scheduledTime, day)).toList();
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
                titleTextStyle:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white60),
                rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white60),
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

          // ── Today's Sessions label ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  isSameDay(_selectedDay, DateTime.now()) 
                      ? "Today's Sessions" 
                      : DateFormat('MMM d, yyyy').format(_selectedDay),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),

          // ── Session list ─────────────────────────────────
          Expanded(
            child: sessions.when(
              data: (list) {
                final filteredList = list.where((s) => isSameDay(s.scheduledTime, _selectedDay)).toList();
                
                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy_outlined, size: 60, color: Colors.white24),
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
                  itemBuilder: (_, i) => _buildSessionCard(filteredList[i], i == 0),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AntigravityTheme.electricPurple)),
              error: (e, _) => const Center(
                  child: Text('Could not load sessions',
                      style: TextStyle(color: Colors.white38))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, bool isFirst) {
    final fmtTime = (DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final a = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $a';
    };
    final end = session.scheduledTime.add(const Duration(hours: 1));
    final timeRange = '${fmtTime(session.scheduledTime)} - ${fmtTime(end)}';

    final tags = (session.topic.split(' ')..retainWhere((w) => w.length > 2))
        .take(2)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1527),
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(
            color: isFirst ? AntigravityTheme.electricPurple : Colors.white12,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2D2040),
                child: Text(
                  session.studentName.isNotEmpty
                      ? session.studentName[0].toUpperCase()
                      : 'M',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.studentName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(session.topic,
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2040),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(timeRange,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFirst
                            ? AntigravityTheme.electricPurple.withValues(alpha: 0.2)
                            : const Color(0xFF2D2040),
                        borderRadius: BorderRadius.circular(20),
                        border: isFirst
                            ? Border.all(
                                color: AntigravityTheme.electricPurple.withValues(alpha: 0.4))
                            : null,
                      ),
                      child: Text(t.toUpperCase(),
                          style: TextStyle(
                              color: isFirst
                                  ? AntigravityTheme.electricPurple
                                  : Colors.white54,
                              fontSize: 10,
                              letterSpacing: 0.8)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon! 🚀'), behavior: SnackBarBehavior.floating));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFirst
                        ? AntigravityTheme.electricPurple
                        : const Color(0xFF2D2040),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(isFirst ? 'Join Call' : 'View Details',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (isFirst) ...[
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2040),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.more_horiz, color: Colors.white70),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
