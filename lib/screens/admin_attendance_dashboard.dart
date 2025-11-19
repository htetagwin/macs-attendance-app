import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/constants.dart';

class AdminAttendanceDashboard extends StatelessWidget {
  const AdminAttendanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('user_role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentGold));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No attendance recorded yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group by user_id to count points and get unique students
          final Map<String, Map<String, dynamic>> usersMap = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final uid = data['user_id'] as String;
            final name = (data['student_name'] as String?)?.trim() ?? 'Unknown Student';
            final email = (data['email'] as String?) ?? '—';

            if (usersMap.containsKey(uid)) {
              usersMap[uid]!['points'] += 1;
            } else {
              usersMap[uid] = {
                'name': name,
                'email': email,
                'points': 1,
              };
            }
          }

          // Convert to list and sort by name A → Z
          final sortedList = usersMap.entries.toList()
            ..sort((a, b) => a.value['name'].compareTo(b.value['name']));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedList.length,
            itemBuilder: (context, index) {
              final entry = sortedList[index];
              final name = entry.value['name'] as String;
              final email = entry.value['email'] as String;
              final points = entry.value['points'] as int;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: accentGold,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryBlack),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                  subtitle: Text(
                    email,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$points',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: accentGold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}