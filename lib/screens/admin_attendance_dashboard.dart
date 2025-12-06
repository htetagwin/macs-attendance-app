import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/constants.dart';

class AdminAttendanceDashboard extends StatelessWidget {
  const AdminAttendanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Block 1: Student Leaderboard
            _buildDashboardCard(
              context,
              title: "Student Leaderboard",
              subtitle: "View points earned by attendance",
              icon: Icons.leaderboard,
              color: accentGold,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentLeaderboardScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Block 2: Attendance by Seminar
            _buildDashboardCard(
              context,
              title: "Attendance by Seminar",
              subtitle: "See who attended which seminar",
              icon: Icons.event_available,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeminarAttendanceScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color,
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SCREEN 1: Student Leaderboard ====================
class StudentLeaderboardScreen extends StatelessWidget {
  const StudentLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Leaderboard"), backgroundColor: accentGold),
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
            return const Center(child: Text("No attendance recorded yet"));
          }

          final Map<String, Map<String, dynamic>> studentMap = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final uid = data['user_id'] as String;
            final name = (data['student_name'] as String?)?.trim() ?? 'Unknown';
            final email = data['email'] as String?;

            studentMap.putIfAbsent(uid, () => {'name': name, 'email': email, 'points': 0});
            studentMap[uid]!['points'] += 1;
          }

          final sorted = studentMap.entries.toList()
            ..sort((a, b) => b.value['points'].compareTo(a.value['points'])); // Highest points first

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final entry = sorted[index];
              final name = entry.value['name'];
              final email = entry.value['email'];
              final points = entry.value['points'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: accentGold,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: primaryBlack, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(email ?? ''),
                  trailing: Chip(
                    backgroundColor: accentGold.withOpacity(0.2),
                    label: Text('$points pt${points == 1 ? '' : 's'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: accentGold)),
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

// ==================== SCREEN 2: Attendance by Seminar ====================
class SeminarAttendanceScreen extends StatelessWidget {
  const SeminarAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance by Seminar"), backgroundColor: accentGold),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentGold));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No attendance yet"));
          }

          // Group by seminar_id
          final Map<String, List<Map<String, dynamic>>> seminarMap = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final seminarId = data['seminar_id'] as String;
            final seminarTitle = data['seminar_title'] as String? ?? 'Untitled Seminar';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

            seminarMap.putIfAbsent(seminarId, () => []);
            seminarMap[seminarId]!.add({
              'seminar_title': seminarTitle,
              'student_name': data['student_name'] ?? 'Unknown',
              'email': data['email'] ?? '',
              'timestamp': timestamp,
            });
          }

          final sortedSeminars = seminarMap.entries.toList()
            ..sort((a, b) {
              final aTime = a.value.first['timestamp'] as DateTime?;
              final bTime = b.value.first['timestamp'] as DateTime?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // Latest first
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedSeminars.length,
            itemBuilder: (context, index) {
              final entry = sortedSeminars[index];
              final seminarId = entry.key;
              final attendees = entry.value;
              final title = attendees.first['seminar_title'];
              final dateStr = attendees.first['timestamp'] != null
                  ? '${(attendees.first['timestamp'] as DateTime).day}/${(attendees.first['timestamp'] as DateTime).month}/${(attendees.first['timestamp'] as DateTime).year}'
                  : 'No date';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.school, color: Colors.white)),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${attendees.length} attendee${attendees.length == 1 ? '' : 's'} • $dateStr'),
                  children: attendees.map((student) {
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.teal.withOpacity(0.2),
                        child: Text(
                          (student['student_name'] as String).isNotEmpty
                              ? (student['student_name'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(student['student_name']),
                      subtitle: Text(student['email']),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}