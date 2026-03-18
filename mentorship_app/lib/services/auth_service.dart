import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

// Web OAuth 2.0 client ID (from Google Cloud Console → Credentials → Web client).
// This is different from the Android client ID!
const _webClientId =
    '1425969683-cj47d0nu227gql7ju1gb9q97vm830a1n.apps.googleusercontent.com';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  static final GoogleSignIn _sharedGoogleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
  );

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? _sharedGoogleSignIn,
       _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Verifies if a college code exists.
  Future<bool> verifyCollegeCode(String code) async {
    if (code.trim().isEmpty) return false;
    final upperCode = code.trim().toUpperCase();

    final snapshot = await _firestore
        .collection('colleges')
        .where('code', isEqualTo: upperCode)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Sign in with Google. Returns the Firebase [User] on success.
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Verifies a college identity and claims it for the user.
  Future<bool> verifyCollegeIdentity({
    required String collegeCode,
    required String identityId,
    required String inviteCode,
    required String uid,
  }) async {
    // Step A: Query for college document
    final collegeSnapshot = await _firestore
        .collection('colleges')
        .where('code', isEqualTo: collegeCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (collegeSnapshot.docs.isEmpty) {
      throw Exception('Invalid College Code');
    }

    final collegeDocId = collegeSnapshot.docs.first.id;

    // Run transaction for atomicity
    return await _firestore.runTransaction((transaction) async {
      final identityRef = _firestore
          .collection('colleges')
          .doc(collegeDocId)
          .collection('identities')
          .doc(identityId.trim());

      final userRef = _firestore.collection('users').doc(uid);

      final identityDoc = await transaction.get(identityRef);
      final userDoc = await transaction.get(userRef);

      // Step C: Check identity existence
      if (!identityDoc.exists) {
        throw Exception('ID not found');
      }

      final data = identityDoc.data()!;

      // Step D: Verify Invite Code
      if (data['inviteCode'] != inviteCode.trim().toUpperCase()) {
        throw Exception('Invalid Invite Code');
      }

      // Step E: Check if identity already claimed
      if (data['isClaimed'] == true && data['claimedBy'] != uid) {
        throw Exception('This ID has already been claimed by another user');
      }

      // Step F: Prevent re-verification if already verified (optional but strict)
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (userData['isVerifiedCollegeUser'] == true) {
          throw Exception('Account is already verified');
        }
      }

      // Step G: Claim identity
      transaction.update(identityRef, {
        'isClaimed': true,
        'claimedBy': uid,
        'claimedAt': FieldValue.serverTimestamp(),
      });

      // Step H: Update user document
      // This is the EXCLUSIVE place where isVerifiedCollegeUser and role are set
      transaction.set(userRef, {
        'isVerifiedCollegeUser': true,
        'role': data['role'] ?? 'student',
        'name':
            data['name'] ??
            (userDoc.exists ? (userDoc.data()!['name'] ?? '') : ''),
        'collegeCode': collegeCode.trim().toUpperCase(),
        'identityId': identityId.trim(),
      }, SetOptions(merge: true));

      return true;
    });
  }

  /// Checks if the currently signed-in user already has a Firestore profile.
  Future<bool> userProfileExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// Creates a new user profile in Firestore.
  Future<void> createUserProfile(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception(
        'Network timeout. Please check your connection and try again.',
      );
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Fetches the current user's [AppUser] profile.
  Future<AppUser?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<void> signOut() async {
    // Set presence to offline before signing out
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
