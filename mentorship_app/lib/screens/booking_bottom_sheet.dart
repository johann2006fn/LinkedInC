import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/antigravity_theme.dart';
import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../models/connection.dart';

class BookingBottomSheet extends ConsumerStatefulWidget {
  final AppUser mentor;

  const BookingBottomSheet({super.key, required this.mentor});

  @override
  ConsumerState<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends ConsumerState<BookingBottomSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  final TextEditingController _goalController = TextEditingController();
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const Text('Book a Session',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Select a convenient time to connect with ${widget.mentor.name.split(' ').first}.',
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 28),

          // ── Date Selector ───────────────────────────────
          const Text('Select Date',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index + 1));
                final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                                   DateFormat('yyyy-MM-dd').format(_selectedDate);
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AntigravityTheme.electricPurple : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Colors.white24 : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('EEE').format(date),
                            style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(DateFormat('d').format(date),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── Time Selector ───────────────────────────────
          const Text('Select Time',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _timeSlots.map((time) {
              final isSelected = _selectedTime == time;
              return GestureDetector(
                onTap: () => setState(() => _selectedTime = time),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AntigravityTheme.electricPurple : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.white24 : Colors.transparent),
                  ),
                  child: Text(time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Goal Field ──────────────────────────────────
          const Text('Your Goal for this Session',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _goalController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'What would you like to discuss?',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Confirm Button ──────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedTime == null || _isLoading) ? null : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AntigravityTheme.electricPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CONFIRM BOOKING',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking() async {
    if (_isLoading) return;
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
      );

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Text('Session booked with ${widget.mentor.name}!', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF1A1527),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking session: $e'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
