import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/user_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/connection_repository.dart';
import '../repositories/chat_repository.dart';
import '../models/app_user.dart';
import '../models/session.dart';
import '../models/connection.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/matchmaking_service.dart';
import 'auth_provider.dart';

// Repository Providers
final userRepositoryProvider = Provider((ref) => UserRepository());
final sessionRepositoryProvider = Provider((ref) => SessionRepository());
final connectionRepositoryProvider = Provider((ref) => ConnectionRepository());
final chatRepositoryProvider = Provider((ref) => ChatRepository());

// Current User Provider
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return null;
  
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUser(user.uid);
});

// Stream Providers
final topMentorsProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).getTopMentors();
});

// Matchmaking Providers
final matchmakingServiceProvider = Provider((ref) => MatchmakingService());

final recommendedMentorsProvider = FutureProvider<List<AppUser>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null || currentUser.role != 'mentee') return [];
  if (currentUser.tags == null || currentUser.tags!.isEmpty) return [];

  final matchmakingService = ref.watch(matchmakingServiceProvider);
  return await matchmakingService.getDailyMatches(topK: 5);
});

final topMenteesProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).getTopMentees();
});

final upcomingSessionsProvider = StreamProvider<List<Session>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(sessionRepositoryProvider).getUpcomingSessions(user.uid);
});

final pendingRequestsProvider = StreamProvider<List<MentorshipConnection>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(connectionRepositoryProvider).getPendingRequests(user.uid);
});

final activeMentorsProvider = StreamProvider<List<MentorshipConnection>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(connectionRepositoryProvider).getActiveMentors(user.uid);
});

final userChatsProvider = StreamProvider<List<Chat>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).getUserChats(user.uid);
});

final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).getChatMessages(chatId);
});

// Mentor Stats Streams
final mentorTotalSessionsProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(0);
  
  return FirebaseFirestore.instance
      .collection('sessions')
      .where('mentorId', isEqualTo: user.uid)
      .where('status', whereIn: ['accepted', 'completed', 'upcoming']) // include relevant statuses
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final mentorStudentsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(0);
  
  return FirebaseFirestore.instance
      .collection('connections')
      .where('mentorId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'accepted')
      .snapshots()
      .map((snapshot) {
    // Count unique studentIds
    final studentIds = snapshot.docs.map((doc) => doc.data()['studentId'] as String?).where((id) => id != null).toSet();
    return studentIds.length;
  });
});
