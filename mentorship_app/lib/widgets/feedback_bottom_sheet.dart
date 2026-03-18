import 'package:flutter/material.dart';
import '../repositories/review_repository.dart';

class FeedbackBottomSheet extends StatefulWidget {
  final String mentorId;
  final String menteeId;
  final String sessionId;
  final String chatId;
  final String messageId;

  const FeedbackBottomSheet({
    super.key,
    required this.mentorId,
    required this.menteeId,
    required this.sessionId,
    required this.chatId,
    required this.messageId,
  });

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  final List<String> _selectedEndorsements = [];
  final List<String> _availableEndorsements = [
    "Great Explainer",
    "Bug Squasher",
    "Patient",
    "Deep Knowledge",
  ];
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);
    try {
      await ReviewRepository().submitReview(
        selectedEndorsements: _selectedEndorsements,
        comment: _commentController.text.trim(),
        mentorId: widget.mentorId,
        menteeId: widget.menteeId,
        chatId: widget.chatId,
        messageId: widget.messageId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted! Thank you.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Positive Feedback',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'How was your session with the mentor?',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _availableEndorsements.map((tag) {
              final isSelected = _selectedEndorsements.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedEndorsements.add(tag);
                    } else {
                      _selectedEndorsements.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Private feedback notes (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit Feedback'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
