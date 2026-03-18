import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorship_app/models/app_user.dart';
import 'package:mentorship_app/models/session.dart';
import 'package:mentorship_app/models/message.dart';
import 'package:mentorship_app/widgets/mentor_card.dart';
import 'package:mentorship_app/widgets/upcoming_session_card.dart';
import 'package:mentorship_app/widgets/session_message_tile.dart';
import 'package:mentorship_app/providers/app_providers.dart';

// -- Helpers ---------------------------------------------------------------

/// Create an [AppUser] with extremely long text to stress-test overflow.
AppUser _longMentor() {
  return AppUser(
    id: 'mentor-overflow-test',
    name: 'Professor Bartholomew Montague Fitzgerald Wellington III',
    email: 'verylongemailaddress@university.edu',
    role: 'mentor',
    subtitle:
        'Distinguished Professor of Advanced Computational Quantum Mechanics and Deep Learning',
    tags: [
      'Machine Learning & Neural Network Architecture',
      'Quantum Computing & Cryptography',
      'Full-Stack Web Development & Cloud Native Infrastructure',
    ],
    bio:
        'Over twenty-five years of dedicated research and mentoring in cutting-edge technology disciplines spanning multiple continents.',
    skills: [
      'TensorFlow Advanced Distributed Training',
      'Kubernetes Container Orchestration',
    ],
    interests: ['Artificial General Intelligence', 'Brain-Computer Interfaces'],
    goals: ['Publish in Nature', 'Build autonomous systems'],
    department: 'Department of Computer Science and Engineering',
    experience: '25+ years in academia and industry',
    endorsements: {
      'Exceptional Machine Learning Researcher & Practitioner': 42,
    },
    sessionsCompleted: 150,
  );
}

/// Create a mock [AppUser] for the current user (watcher).
AppUser _mockCurrentUser() {
  return AppUser(
    id: 'current-user-id',
    name: 'Test Student',
    email: 'student@test.com',
    role: 'student',
    savedMentors: [],
  );
}

/// Create a [Session] with extremely long text fields.
Session _longSession() {
  return Session(
    id: 'session-overflow-test',
    mentorId: 'mentor-overflow-test',
    studentId: 'student-overflow-test',
    chatId: 'chat-overflow-test',
    topic:
        'Introduction to Advanced Quantum Machine Learning and its Applications in Financial Modelling',
    scheduledTime: DateTime.now().add(const Duration(hours: 2)),
    status: 'upcoming',
    mentorName:
        'Professor Bartholomew Montague Fitzgerald Wellington III',
    studentName:
        'Alexandra Constantinescu-Vanderbilt de Montmorency',
  );
}

/// Create a [Message] with a very long session topic for SessionMessageTile.
Message _longSessionMessage() {
  return Message(
    id: 'msg-overflow-test',
    chatId: 'chat-overflow-test',
    senderId: 'mentor-overflow-test',
    content: 'Session proposed',
    timestamp: DateTime.now(),
    type: MessageType.sessionProposal,
    metadata: {
      'sessionTopic':
          'Deep Dive into Transformer Architecture Design Patterns and Large Language Model Fine-Tuning Strategies for Enterprise Applications',
      'proposedTime': null,
      'sessionStatus': 'proposed',
    },
    mentorId: 'mentor-overflow-test',
    menteeId: 'student-overflow-test',
    menteeName: 'Alexandra Constantinescu-Vanderbilt de Montmorency',
  );
}

/// Builds a constrained 320×568 viewport around [child] with optional
/// Riverpod provider overrides for [currentUserProvider].
Widget _buildApp(Widget child, {AppUser? mockUser}) {
  return ProviderScope(
    overrides: [
      if (mockUser != null)
        currentUserProvider.overrideWith((_) async => mockUser),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 568,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

// -- Tests -----------------------------------------------------------------

void main() {
  group('MentorCard — Overflow Resilience', () {
    testWidgets('renders without overflow on 320px-wide screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          MentorCard(mentor: _longMentor()),
          mockUser: _mockCurrentUser(),
        ),
      );

      await tester.pumpAndSettle();

      // If we get here without a FlutterError about overflow, the test passes.
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with long endorsement tag without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          MentorCard(mentor: _longMentor()),
          mockUser: _mockCurrentUser(),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('UpcomingSessionCard — Overflow Resilience', () {
    testWidgets('renders without overflow on 320px-wide screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(UpcomingSessionCard(session: _longSession())),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('SessionMessageTile — Overflow Resilience', () {
    testWidgets('renders without overflow on 320px-wide screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          SessionMessageTile(
            message: _longSessionMessage(),
            isCurrentUserMentor: false,
            currentUserName: 'Test Student',
            currentUserId: 'test-user-id',
          ),
        ),
      );

      // Let animations start (tile has AnimationController)
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
