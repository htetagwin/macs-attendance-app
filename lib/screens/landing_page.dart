import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:simple_attendance_app/models/user_model.dart';
import 'package:simple_attendance_app/screens/home.dart';
import 'package:simple_attendance_app/screens/student_attendance_page.dart';
import 'package:simple_attendance_app/screens/more_page.dart';
import 'package:simple_attendance_app/screens/admin_dashboard.dart';
import 'package:simple_attendance_app/services/auth_service.dart';
import 'package:simple_attendance_app/constants.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final AuthService _auth = AuthService();
  int _currentIndex = 0;

  void _showAnnouncementDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(data['title'] ?? 'Announcement',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryBlack),
            textAlign: TextAlign.center),
        content: Text(data['description'] ?? 'No details available.',
            style: const TextStyle(fontSize: 16, height: 1.6), textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: primaryBlack))),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentGold));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No announcements yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, i) {
            final data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(backgroundColor: accentGold, child: const Icon(Icons.campaign, color: primaryBlack)),
                title: Text(data['title'] ?? 'No title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                subtitle: Text(data['description'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: accentGold),
                onTap: () => _showAnnouncementDetails(data),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserModel?>(
      builder: (context, user, child) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: accentGold)));
        }

        final bool isAdmin = user.role?.toLowerCase() == 'admin';

        final List<Widget> screens = [
          _buildAnnouncementsScreen(),      // 0
          const Home(),                     // 1
          const StudentAttendancePage(),    // 2
          const MorePage(),                 // 3 - always More (students & admins)
        ];

        final List<String> titles = ['Announcements', 'Seminars', 'Attendance', 'More'];

        return Scaffold(
          backgroundColor: backgroundWhite,
          appBar: AppBar(
            backgroundColor: primaryBlack,
            title: Text(titles[_currentIndex], style: const TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: 22)),
            centerTitle: true,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: accentGold),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
                ),
              TextButton.icon(
                onPressed: () => _auth.signOut(),
                icon: const Icon(Icons.logout, color: accentGold),
                label: const Text('Logout', style: TextStyle(color: accentGold)),
              ),
            ],
          ),
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: accentGold,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Announcements'),
              BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Seminars'),
              BottomNavigationBarItem(icon: Icon(Icons.how_to_reg), label: 'Attendance'),
              BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
        );
      },
    );
  }
}