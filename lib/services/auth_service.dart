import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convert Firebase User → UserModel (with role from Firestore)
  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      role: 'normal', // default, will be overridden by stream
    );
  }

  // Stream: Listen to auth + fetch role from Firestore
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (!doc.exists) {
          debugPrint('User doc not found for UID: ${firebaseUser.uid}');
          return _userFromFirebaseUser(firebaseUser);
        }

        final data = doc.data() as Map<String, dynamic>;
        final role = data['role']?.toString().trim().toLowerCase() ?? 'student';

        return UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: data['name']?.toString() ?? '',
          role: role,
        );
      } catch (e) {
        debugPrint('Error fetching user role: $e');
        return _userFromFirebaseUser(firebaseUser);
      }
    });
  }

  // SIGN IN
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Signing in: $email');
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      debugPrint('Sign-in successful');
      return null; // Success → let Wrapper handle navigation
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-in error: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account is disabled.';
        default:
          return 'Sign-in failed. Try again.';
      }
    } catch (e) {
      debugPrint('Unexpected sign-in error: $e');
      return 'Sign-in failed: $e';
    }
  }

  // REGISTER – Only allows 'student' or 'faculty'
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    // Validate role
    if (!['student', 'faculty'].contains(role.toLowerCase())) {
      return 'Invalid role. Choose Student or Faculty.';
    }

    UserCredential? userCredential;
    try {
      debugPrint('Registering: $email as $role');

      // Create Firebase Auth user
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Save to Firestore
      await _firestore.collection('users').doc(uid).set({
        'email': email.trim(),
        'name': name.trim(),
        'role': role.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('User registered: $uid');
      return null; // Success → Wrapper auto-switches
    } on FirebaseAuthException catch (e) {
      // Clean up auth user if Firestore fails
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }

      debugPrint('Auth error: ${e.code}');
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email already in use.';
        case 'weak-password':
          return 'Password too weak (6+ chars).';
        case 'invalid-email':
          return 'Invalid email.';
        default:
          return 'Registration failed.';
      }
    } on FirebaseException catch (e) {
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }
      return 'Database error: ${e.message}';
    } catch (e) {
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }
      return 'Unexpected error: $e';
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('Signed out');
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
  }

  // GET CURRENT USER (sync)
  User? getCurrentUser() => _auth.currentUser;
}