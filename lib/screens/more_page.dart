import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/constants.dart';
import 'package:simple_attendance_app/services/auth_service.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          // This fixes the overflow
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get(),
                builder: (context, snapshot) {
                  String name = user.email?.split('@').first ?? 'Student';
                  String email = user.email ?? '';
                  String role = 'Student';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;

                    final first = data['first_name']?.toString().trim() ?? '';
                    final last = data['last_name']?.toString().trim() ?? '';
                    final fullName = '$first $last'.trim();
                    if (fullName.isNotEmpty) name = fullName;

                    final rawRole = (data['role'] as String?)
                        ?.toLowerCase()
                        .trim();
                    role = rawRole == 'admin'
                        ? 'Administrator'
                        : rawRole == 'faculty'
                        ? 'Faculty'
                        : 'Student';
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: accentGold,
                          child: const Icon(
                            Icons.person,
                            size: 56,
                            color: primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: primaryBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: accentGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Menu Items
              _buildMenuTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile editing coming soon'),
                    ),
                  );
                },
              ),
              _buildMenuTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact: csfhsu@gmail.com')),
                  );
                },
              ),
              _buildMenuTile(
                icon: Icons.info_outline,
                title: 'About App',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'University Attendance',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(
                      Icons.school,
                      size: 50,
                      color: accentGold,
                    ),
                    children: const [
                      Text(
                        'A simple and elegant attendance system for university seminars.',
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40), // Space before logout
              // Sign Out Button
              _buildMenuTile(
                icon: Icons.logout,
                title: 'Sign Out',
                color: errorRed,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Sign Out?'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(color: errorRed),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await AuthService().signOut();
                  }
                },
              ),

              const SizedBox(height: 20), // Safe bottom space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: (color ?? accentGold).withOpacity(0.15),
          child: Icon(icon, color: color ?? accentGold),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: color ?? primaryBlack,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }
}
