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

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              // On web: must match the meta tag in index.html
              clientId: kIsWeb ? _webClientId : null,
            ),
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

    final UserCredential result =
        await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Verifies a college code against the `colleges` Firestore collection.
  /// Checks if the entered code exists in any document's `access_codes` array.
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
      throw Exception('Network timeout. Please check your connection and try again.');
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
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
