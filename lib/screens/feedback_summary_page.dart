import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/constants.dart';

class FeedbackSummaryPage extends StatefulWidget {
  const FeedbackSummaryPage({super.key});

  @override
  State<FeedbackSummaryPage> createState() => _FeedbackSummaryPageState();
}

class _FeedbackSummaryPageState extends State<FeedbackSummaryPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final double padding = isSmall ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [


            // Option Cards
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildOptionCard(
                      title: 'Student Feedback',
                      subtitle: 'View feedback submitted by students',
                      icon: Icons.school_rounded,
                      color: Colors.blue.shade100,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserTypeFeedbackPage(role: 'student')),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildOptionCard(
                      title: 'Faculty Feedback',
                      subtitle: 'View feedback submitted by faculty',
                      icon: Icons.person_outline_rounded,
                      color: Colors.purple.shade100,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserTypeFeedbackPage(role: 'faculty')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 22 : 28),
          child: Row(
            children: [
              CircleAvatar(
                radius: isSmall ? 34 : 40,
                backgroundColor: color,
                child: Icon(icon, color: primaryBlack, size: isSmall ? 36 : 42),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmall ? 19 : 21,
                        fontWeight: FontWeight.bold,
                        color: primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmall ? 15 : 16,
                        color: primaryBlack.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: accentGold, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

// USER TYPE FEEDBACK LIST (Student / Faculty)
class UserTypeFeedbackPage extends StatefulWidget {
  final String role;
  const UserTypeFeedbackPage({super.key, required this.role});

  @override
  State<UserTypeFeedbackPage> createState() => _UserTypeFeedbackPageState();
}

class _UserTypeFeedbackPageState extends State<UserTypeFeedbackPage> {
  String? _selectedSeminarId;
  String? _selectedSeminarTitle;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    final padding = isSmall ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        child: _selectedSeminarId != null
            ? SeminarFeedbackDetailPage(
                seminarId: _selectedSeminarId!,
                seminarTitle: _selectedSeminarTitle!,
                role: widget.role,
                onBack: () => setState(() {
                  _selectedSeminarId = null;
                  _selectedSeminarTitle = null;
                }),
              )
            : Column(
                children: [
                  // Custom Header with Back Arrow
                  Container(
                    padding: EdgeInsets.fromLTRB(padding, 60, padding, padding),
                    decoration: const BoxDecoration(
                      color: primaryBlack,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: accentGold, size: 32),
                          onPressed: () => Navigator.pop(context), // This is the back arrow you wanted
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.role.capitalize()} Feedback',
                          style: const TextStyle(color: accentGold, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Seminar List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('seminars').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: accentGold));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _emptyState('No seminars available');
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, i) {
                            final doc = snapshot.data!.docs[i];
                            final data = doc.data() as Map<String, dynamic>;
                            final id = doc.id;
                            final title = data['title'] ?? 'Untitled Seminar';

                            return FutureBuilder<int>(
                              future: _countFeedback(id),
                              builder: (context, snap) {
                                final count = snap.data ?? 0;
                                return _seminarCard(
                                  title: title,
                                  count: count,
                                  onTap: count > 0
                                      ? () => setState(() {
                                            _selectedSeminarId = id;
                                            _selectedSeminarTitle = title;
                                          })
                                      : null,
                                );
                              },
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

  Future<int> _countFeedback(String seminarId) async {
    final snap = await FirebaseFirestore.instance
        .collection('feedback')
        .where('seminar_id', isEqualTo: seminarId)
        .get();

    int count = 0;
    for (var doc in snap.docs) {
      final data = doc.data();
      final uid = data['user_id'] as String?;
      if (uid == null) continue;

      if (data['role'] == widget.role) {
        count++;
        continue;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data()?['role'] == widget.role) {
        count++;
      }
    }
    return count;
  }

  Widget _seminarCard({required String title, required int count, VoidCallback? onTap}) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        enabled: onTap != null,
        contentPadding: EdgeInsets.all(isSmall ? 18 : 22),
        leading: CircleAvatar(
          radius: isSmall ? 30 : 34,
          backgroundColor: count > 0 ? accentGold.withOpacity(0.15) : Colors.grey.shade200,
          child: Icon(Icons.feedback_rounded, color: count > 0 ? accentGold : Colors.grey[600], size: isSmall ? 30 : 34),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 17 : 19)),
        subtitle: Text('$count feedback${count == 1 ? '' : 's'}', style: const TextStyle(fontSize: 15)),
        trailing: onTap != null
            ? Icon(Icons.arrow_forward_ios_rounded, color: accentGold, size: 22)
            : const SizedBox(width: 48),
        onTap: onTap,
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(msg, style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

// DETAILED FEEDBACK PER SEMINAR
class SeminarFeedbackDetailPage extends StatelessWidget {
  final String seminarId;
  final String seminarTitle;
  final String role;
  final VoidCallback onBack;

  const SeminarFeedbackDetailPage({
    super.key,
    required this.seminarId,
    required this.seminarTitle,
    required this.role,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final padding = isSmall ? 16.0 : 24.0;

    return Column(
      children: [
        // Header with back arrow
        Container(
          padding: EdgeInsets.fromLTRB(padding, 60, padding, padding),
          decoration: const BoxDecoration(
            color: primaryBlack,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: accentGold, size: 32),
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  seminarTitle,
                  style: const TextStyle(color: accentGold, fontSize: 24, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Rest of your detailed feedback content...
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .where('seminar_id', isEqualTo: seminarId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: accentGold));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState('No $role feedback yet');
              }

              return FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _filterByRole(snapshot.data!.docs),
                builder: (context, filtered) {
                  if (!filtered.hasData) return const Center(child: CircularProgressIndicator(color: accentGold));
                  final feedbacks = filtered.data!;
                  if (feedbacks.isEmpty) return _emptyState('No $role feedback');

                  return _buildList(context, feedbacks, padding);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<QueryDocumentSnapshot>> _filterByRole(List<QueryDocumentSnapshot> docs) async {
    final valid = <QueryDocumentSnapshot>[];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final uid = data['user_id'] as String?;
      if (uid == null) continue;

      if (data['role'] == role) {
        valid.add(doc);
        continue;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data()?['role'] == role) {
        valid.add(doc);
      }
    }
    return valid;
  }

  Widget _buildList(BuildContext context, List<QueryDocumentSnapshot> feedbacks, double padding) {
    final Map<String, List<int>> ratings = {
      'Introduction': [], 'Content': [], 'Flow': [], 'Presentation': [], 'Engagement': []
    };
    final List<Map<String, dynamic>> comments = [];

    for (var doc in feedbacks) {
      final data = doc.data() as Map<String, dynamic>;
      final r = data['ratings'] as Map<String, dynamic>? ?? {};
      r.forEach((k, v) {
        if (v is int && ratings.containsKey(k)) ratings[k]!.add(v);
      });
      comments.add({
        'email': data['email'] ?? 'Anonymous',
        'comment': data['feedback'] ?? '',
        'timestamp': data['timestamp'],
      });
    }

    final avg = <String, double>{};
    ratings.forEach((k, v) => avg[k] = v.isEmpty ? 0.0 : v.reduce((a, b) => a + b) / v.length);
    final overall = avg.values.isEmpty ? 0.0 : avg.values.reduce((a, b) => a + b) / 5;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  const Text('Overall Rating', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentGold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _starRow(overall, 36),
                      const SizedBox(width: 16),
                      Text(overall.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                      Text(' (${feedbacks.length})', style: TextStyle(color: primaryBlack.withOpacity(0.6), fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('By Category', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentGold)),
          const SizedBox(height: 12),
          ...avg.entries.map((e) => _categoryCard(e.key, e.value)),
          const SizedBox(height: 24),
          const Text('Comments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentGold)),
          const SizedBox(height: 12),
          ...comments.map((c) => _commentCard(c)),
        ],
      ),
    );
  }

  Widget _starRow(double r, double s) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) => Icon(
              i < r.floor() ? Icons.star_rounded : i < r ? Icons.star_half_rounded : Icons.star_border_rounded,
              color: accentGold,
              size: s,
            )),
      );

  Widget _categoryCard(String label, double avg) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: _starRow(avg, 28),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        trailing: Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: accentGold, fontSize: 20)),
      ),
    );
  }

  Widget _commentCard(Map<String, dynamic> c) {
    final comment = c['comment'] as String;
    if (comment.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c['email'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
              child: Text(comment, style: const TextStyle(height: 1.6, fontSize: 15)),
            ),
            if (c['timestamp'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('— ${_format(c['timestamp'])}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  String _format(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 90, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(msg, style: const TextStyle(fontSize: 19, color: Colors.grey)),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}