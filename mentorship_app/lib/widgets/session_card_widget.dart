import 'package:flutter/material.dart';
import '../models/message.dart';

class SessionCardWidget extends StatelessWidget {
  final Message message;
  final bool isMentor;
  final VoidCallback? onConfirm;
  final VoidCallback? onChangeTime;
  final VoidCallback? onJoinCall;

  const SessionCardWidget({
    super.key,
    required this.message,
    required this.isMentor,
    this.onConfirm,
    this.onChangeTime,
    this.onJoinCall,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata ?? {};
    final proposedTime = metadata['proposedTime'] ?? 'TBD';
    final topic = metadata['topic'] ?? 'Mentorship Session';
    final aiBrief = metadata['aiBrief'] ?? '';
    final status = metadata['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: status == 'confirmed'
              ? Colors.green.shade100
              : Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: status == 'confirmed'
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == 'confirmed'
                      ? Icons.video_call
                      : Icons.calendar_today,
                  color: status == 'confirmed' ? Colors.green : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'confirmed'
                          ? 'Session Confirmed'
                          : 'Session Proposal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: status == 'confirmed'
                            ? Colors.green
                            : Colors.blue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      topic,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(proposedTime, style: const TextStyle(color: Colors.black87)),
            ],
          ),
          if (isMentor && aiBrief.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.purple),
                      SizedBox(width: 6),
                      Text(
                        'AI BRIEF FOR MENTOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aiBrief,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (status == 'pending')
            isMentor
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onChangeTime,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Change Time'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Waiting for Professor to confirm...',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
          if (status == 'confirmed')
            ElevatedButton.icon(
              onPressed: onJoinCall,
              icon: const Icon(Icons.videocam),
              label: const Text('Join Video Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
