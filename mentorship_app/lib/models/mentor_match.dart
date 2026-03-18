import 'app_user.dart';

class MentorMatch {
  final AppUser mentor;
  final int score;
  final String reason;

  MentorMatch({
    required this.mentor,
    required this.score,
    required this.reason,
  });
}
