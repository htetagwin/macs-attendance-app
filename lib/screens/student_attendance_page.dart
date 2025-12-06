import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:simple_attendance_app/constants.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // TOP CARD (Profile + Points)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                          elevation: 12,
                          shadowColor: accentGold.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: accentGold,
                                  child: Icon(Icons.person, size: 52, color: primaryBlack),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryBlack),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user.email ?? 'No email',
                                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  '$points',
                                  style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: accentGold),
                                ),
                                Text(
                                  points == 1 ? 'Attendance Point' : 'Attendance Points',
                                  style: TextStyle(fontSize: 19, color: Colors.grey[700], fontWeight: FontWeight.w600),
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

            // TITLE
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Attendance History',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlack),
                ),
              ),
            ),

            // ATTENDANCE LIST
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('user_id', isEqualTo: uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No attendance yet', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Your attended seminars will appear here', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      final String title = data['seminar_title'] ?? 'Untitled Seminar';
                      final Timestamp? loginTs = data['login_date'] as Timestamp?;
                      final String loginTime = data['login_time'] ?? '—';
                      final DateTime? date = loginTs?.toDate() ?? (data['timestamp'] as Timestamp?)?.toDate();
                      final String formattedDate = date != null
                          ? DateFormat('EEE, d MMM yyyy').format(date)
                          : 'Date unknown';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: accentGold.withOpacity(0.15),
                              child: Icon(Icons.check_circle, color: accentGold, size: 28),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('Checked in: $loginTime', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                            // Arrow removed
                            // trailing: null or just remove the trailing property entirely
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}