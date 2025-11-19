import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:simple_attendance_app/models/user_model.dart';
import 'package:simple_attendance_app/screens/authenticate/authenticate.dart';
import 'package:simple_attendance_app/screens/landing_page.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserModel?>.value(
      initialData: null,
      value: FirebaseAuth.instance.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;

        try {
          // Fetch user document from Firestore
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get()
              .timeout(const Duration(seconds: 10));

          if (!doc.exists) {
            debugPrint('Wrapper: No Firestore doc for UID: ${firebaseUser.uid}');
            return UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email,
            );
          }

          final data = doc.data() as Map<String, dynamic>;

          return UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            name: data['name']?.toString().trim(),
            role: data['role']?.toString().trim().toLowerCase(),
          );
        } catch (e) {
          debugPrint('Wrapper: Error fetching user data: $e');
          return UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
          );
        }
      }),
      child: const _WrapperContent(),
    );
  }
}

class _WrapperContent extends StatelessWidget {
  const _WrapperContent();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    debugPrint(
      'Wrapper: User = ${user?.uid ?? 'null'}, '
      'Name = ${user?.name ?? 'none'}, '
      'Role = ${user?.role ?? 'none'}',
    );

    return user == null ? const Authenticate() : const LandingPage();
  }
}