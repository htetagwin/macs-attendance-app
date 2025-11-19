import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/constants.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  Future<bool> _confirm(BuildContext context, String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: backgroundWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            content: Text(content, style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle(color: primaryBlack, fontSize: 16)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGold,
                  foregroundColor: primaryBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // User List — same clean style as attendance page
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: accentGold));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading users', style: TextStyle(color: errorRed)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_alt_outlined, size: 90, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          const Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final doc = users[index];
                      final user = doc.data() as Map<String, dynamic>;
                      final userId = doc.id;
                      final email = user['email']?.toString() ?? 'No Email';
                      final firstName = user['first_name']?.toString() ?? '';
                      final lastName = user['last_name']?.toString() ?? '';
                      final fullName = '$firstName $lastName'.trim();
                      final displayName = fullName.isNotEmpty ? fullName : email.split('@').first;

                      final role = (user['role']?.toString() ?? 'student').toLowerCase();
                      final bool isFaculty = role == 'faculty';

                      return Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: isFaculty ? Colors.purple.shade100 : Colors.blue.shade100,
                                    child: Icon(
                                      isFaculty ? Icons.person_outline_rounded : Icons.school_rounded,
                                      color: primaryBlack,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isFaculty ? Colors.purple.shade100 : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isFaculty ? 'Faculty' : 'Student',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isFaculty ? Colors.purple.shade900 : Colors.blue.shade900,
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  ElevatedButton.icon(
                                    icon: Icon(isFaculty ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 18),
                                    label: Text(
                                      isFaculty ? 'Make Student' : 'Make Faculty',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentGold,
                                      foregroundColor: primaryBlack,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      final target = isFaculty ? 'student' : 'faculty';
                                      final confirm = await _confirm(context, 'Change Role?', 'Set $displayName as $target?');
                                      if (!confirm || !context.mounted) return;

                                      try {
                                        await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': target});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$displayName → $target'), backgroundColor: successGreen),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed: $e'), backgroundColor: errorRed),
                                        );
                                      }
                                    },
                                  ),

                                  const SizedBox(width: 8),

                                  IconButton(
                                    icon: const Icon(Icons.delete_forever_rounded, color: errorRed, size: 28),
                                    onPressed: () async {
                                      final confirm = await _confirm(context, 'Delete User?', 'Permanently remove $displayName?');
                                      if (!confirm || !context.mounted) return;

                                      try {
                                        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$displayName deleted'), backgroundColor: successGreen),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed: $e'), backgroundColor: errorRed),
                                        );
                                      }
                                    },
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}