import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mentorship_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: SeedRunner())),
    ),
  );
}

class SeedRunner extends StatefulWidget {
  const SeedRunner({super.key});

  @override
  State<SeedRunner> createState() => _SeedRunnerState();
}

class _SeedRunnerState extends State<SeedRunner> {
  String status =
      'Enter your Mentor UID and press button to inject pending requests into Firestore.';
  final TextEditingController _uidController = TextEditingController();

  Future<void> _injectPendingRequests() async {
    final targetMentorId = _uidController.text.trim();
    if (targetMentorId.isEmpty) {
      setState(() => status = 'Error: Please enter a Mentor UID.');
      return;
    }

    setState(() => status = 'Injecting...');
    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch the actual user document to get their name
      final userDoc = await firestore
          .collection('users')
          .doc(targetMentorId)
          .get();
      final targetMentorName = userDoc.exists
          ? (userDoc.data()?['name'] ?? 'Test Mentor')
          : 'Test Mentor';

      final batch = firestore.batch();

      final dummyStudents = [
        {'id': 'dummy_student_1', 'name': 'Alice Smith'},
        {'id': 'dummy_student_2', 'name': 'Bob Jones'},
        {'id': 'dummy_student_3', 'name': 'Charlie Brown'},
      ];

      for (var student in dummyStudents) {
        final docRef = firestore.collection('connections').doc();
        batch.set(docRef, {
          'mentorId': targetMentorId,
          'studentId': student['id'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'mentorName': targetMentorName,
          'mentorSubtitle': 'Senior Developer',
          'mentorTags': ['Flutter', 'Firebase'],
          'studentName': student['name'],
          'otherUserName': student['name'],
          'otherUserId': student['id'],
        });
      }

      await batch.commit();
      setState(
        () => status =
            'Success! Added 3 pending requests to $targetMentorName (ID: $targetMentorId)',
      );
    } catch (e) {
      setState(() => status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _uidController,
            decoration: const InputDecoration(
              labelText: 'Mentor UID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _injectPendingRequests,
            child: const Text('Inject Pending Requests'),
          ),
        ],
      ),
    );
  }
}
