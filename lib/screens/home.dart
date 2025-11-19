import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/screens/seminar_detail_page.dart';
import 'package:simple_attendance_app/constants.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double padding = screenWidth < 600 ? 16.0 : 20.0;
    final double titleFontSize = screenWidth < 600 ? 18.0 : 20.0;
    final double textFontSize = screenWidth < 600 ? 14.0 : 16.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: padding / 2),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('seminars')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: accentGold));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 80, color: primaryBlack.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No seminars scheduled',
                          style: TextStyle(fontSize: 18, color: primaryBlack.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final seminarId = doc.id;
                    final title = data['title'] ?? 'Untitled Seminar';
                    final description = data['abstract'] ?? data['description'] ?? 'No description available';

                    final Timestamp? timestamp = data['date'] as Timestamp?;
                    final DateTime date = timestamp?.toDate() ?? DateTime.now();
                    final bool isPast = date.isBefore(DateTime.now());

                    final formattedDate = '${date.day}/${date.month}/${date.year}';

                    return Card(
                      elevation: isPast ? 1 : 4,
                      color: isPast ? Colors.grey.shade100 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: isPast
                            ? BorderSide(color: Colors.grey.shade400, width: 1.5)
                            : BorderSide.none,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SeminarDetailPage(seminarId: seminarId)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PAST SEMINAR BANNER — VERY PROMINENT
                              if (isPast)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'PAST SEMINAR',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),

                              // Title
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: isPast ? Colors.grey.shade700 : primaryBlack,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Description
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: textFontSize,
                                  color: isPast ? Colors.grey.shade600 : primaryBlack.withOpacity(0.8),
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),

                              // Date + Button Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: isPast ? Colors.grey.shade600 : accentGold,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: textFontSize - 1,
                                          color: isPast ? Colors.grey.shade600 : primaryBlack.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),

                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => SeminarDetailPage(seminarId: seminarId)),
                                    ),
                                    icon: const Icon(Icons.arrow_forward, size: 16),
                                    label: Text(isPast ? 'View Past' : 'View Details'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPast ? Colors.grey.shade400 : accentGold,
                                      foregroundColor: isPast ? Colors.grey.shade700 : primaryBlack,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}