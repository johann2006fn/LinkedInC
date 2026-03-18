import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/antigravity_theme.dart';

class PostSessionFeedbackSheet extends StatefulWidget {
  final String mentorId;

  const PostSessionFeedbackSheet({super.key, required this.mentorId});

  @override
  State<PostSessionFeedbackSheet> createState() => _PostSessionFeedbackSheetState();
}

class _PostSessionFeedbackSheetState extends State<PostSessionFeedbackSheet> {
  final List<String> _tags = [
    'Code Wizard',
    'Bug Squasher',
    'Logic Master',
    'Patient Guide',
    'Clear Communicator',
    'Motivational',
    'Deep Diver',
    'Resourceful',
  ];

  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  Future<void> _submitEndorsement() async {
    if (_selectedTags.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> updates = {};
      for (final tag in _selectedTags) {
        updates['endorsements.$tag'] = FieldValue.increment(1);
      }
      updates['sessionsCompleted'] = FieldValue.increment(1);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mentorId)
          .update(updates);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank You! Endorsement submitted successfully.'),
            backgroundColor: AntigravityTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AntigravityTheme.softRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AntigravityTheme.midnightBlue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Endorse your Mentor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select attributes that best describe your session experience.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: AntigravityTheme.electricPurple.withValues(alpha: 0.2),
                  checkmarkColor: AntigravityTheme.electricPurple,
                  labelStyle: TextStyle(
                    color: isSelected ? AntigravityTheme.electricPurple : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AntigravityTheme.electricPurple
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_selectedTags.isEmpty || _isSubmitting) ? null : _submitEndorsement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AntigravityTheme.electricPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Endorsement',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
