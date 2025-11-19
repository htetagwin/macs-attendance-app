import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/constants.dart';
import 'package:simple_attendance_app/screens/add_announcement_page.dart';
import 'package:simple_attendance_app/screens/add_seminar_page.dart';
import 'package:simple_attendance_app/screens/admin_attendance_dashboard.dart';
import 'package:simple_attendance_app/screens/feedback_summary_page.dart';
import 'package:simple_attendance_app/screens/manage_users_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String? _selectedSeminarId;
  bool _showQR = false;

  final List<String> _titles = [
    'Dashboard',
    'Announcements',
    'Attendance',
    'Feedback',
    'Manage Users',
  ];

  Widget get currentPage {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return const AddAnnouncementPage();
      case 2:
        return const AdminAttendanceDashboard();
      case 3:
        return const FeedbackSummaryPage();
      case 4:
        return const ManageUsersPage();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          if (_showQR && _selectedSeminarId != null) _buildQRCodeDisplay(),
          const SizedBox(height: 24),
          _buildRecentSeminars(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.event, color: primaryBlack),
            label: const Text('Manage Seminars', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGold,
              foregroundColor: primaryBlack,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSeminarPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(_showQR ? Icons.close : Icons.qr_code_2, color: primaryBlack),
            label: Text(_showQR ? 'Hide QR' : 'Show QR', style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _showQR ? errorRed : accentGold,
              foregroundColor: primaryBlack,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => setState(() {
              _showQR = !_showQR;
              if (!_showQR) _selectedSeminarId = null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('seminars').snapshots(),
      builder: (context, snapshot) {
        final total = snapshot.data?.docs.length ?? 0;
        final today = snapshot.data?.docs.where((doc) {
              final date = (doc['date'] as Timestamp?)?.toDate();
              if (date == null) return false;
              final now = DateTime.now();
              return date.year == now.year && date.month == now.month && date.day == now.day;
            }).length ?? 0;

        return Row(
          children: [
            Expanded(child: _statCard('Total Seminars', total.toString(), Icons.event, accentGold)),
            const SizedBox(width: 16),
            Expanded(child: _statCard('Today', today.toString(), Icons.today, successGreen)),
          ],
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: primaryBlack.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryBlack)),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeDisplay() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('seminars').doc(_selectedSeminarId!).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final title = data['title'] ?? 'Seminar';
        final shortCode = data['attendance_code_short'] ?? 'N/A';

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlack)),
                const SizedBox(height: 16),
                QrImageView(
                  data: _selectedSeminarId!,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    shortCode,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: accentGold),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Students scan or enter code', style: TextStyle(color: primaryBlack, fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Code'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlack, foregroundColor: accentGold),
                  onPressed: () {
                    // In real app, use clipboard
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied: $shortCode')));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSeminars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Seminars', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlack)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSeminarPage())),
              child: const Text('View All', style: TextStyle(color: accentGold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('seminars').orderBy('date', descending: true).limit(5).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: accentGold));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('No seminars yet', style: TextStyle(color: primaryBlack.withOpacity(0.6))),
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Untitled';
                final date = (data['date'] as Timestamp?)?.toDate();
                final code = data['attendance_code_short'] ?? 'N/A';
                final isSelected = _showQR && _selectedSeminarId == doc.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: isSelected ? accentGold.withOpacity(0.1) : null,
                  child: ListTile(
                    onTap: () {
                      if (_showQR) {
                        setState(() => _selectedSeminarId = doc.id);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSeminarPage()));
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: accentGold.withOpacity(0.2),
                      child: Icon(Icons.event, color: accentGold),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      date != null
                          ? '${_formatDate(date)} • Code: $code'
                          : 'Code: $code',
                      style: TextStyle(fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) const Icon(Icons.check_circle, color: successGreen),
                        if (!isSelected && _showQR) const Icon(Icons.qr_code, color: accentGold, size: 20),
                        if (!_showQR) const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final input = DateTime(date.year, date.month, date.day);

    if (input == today) return 'Today';
    if (input == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double headerFontSize = screenWidth < 600 ? 20.0 : 26.0;

    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: primaryBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: accentGold), // This makes back arrow GOLD
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: headerFontSize),
          ),
        centerTitle: true, // Optional: looks better centered
      ),
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: primaryBlack,
        selectedItemColor: accentGold,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Announce'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Feedback'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }
}