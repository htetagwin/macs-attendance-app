import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_attendance_app/constants.dart';

class StudentAttendancePage extends StatelessWidget {
  const StudentAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // reduced vertical padding
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (context, userSnap) {
                String displayName = user.email?.split('@').first.capitalize() ?? 'Student';

                if (userSnap.hasData && userSnap.data!.exists) {
                  final data = userSnap.data!.data() as Map<String, dynamic>;
                  final first = (data['first_name'] as String?)?.trim() ?? '';
                  final last = (data['last_name'] as String?)?.trim() ?? '';
                  final full = '$first $last'.trim();
                  if (full.isNotEmpty) displayName = full;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('attendance')
                      .where('user_id', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, attSnap) {
                    final int points = attSnap.hasData ? attSnap.data!.docs.length : 0;

                    return Card(
                      elevation: 10,
                      shadowColor: accentGold.withOpacity(0.25),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24), // smaller padding
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 38, // smaller avatar
                              backgroundColor: accentGold,
                              child: Icon(Icons.person, size: 44, color: primaryBlack),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryBlack,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user.email ?? 'No email',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '$points',
                              style: const TextStyle(
                                fontSize: 68, // smaller but still bold
                                fontWeight: FontWeight.bold,
                                color: accentGold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              points == 1 ? 'Attendance Point' : 'Attendance Points',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}