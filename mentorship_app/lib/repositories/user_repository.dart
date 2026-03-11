import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  Future<void> createUser(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap())
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Network timeout. Please check your connection and try again.');
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Stream<List<AppUser>> getTopMentors() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }

  Stream<List<AppUser>> getTopMentees() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentee')
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }
}
