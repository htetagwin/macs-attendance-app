import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/services/database_service.dart';
import 'package:simple_attendance_app/constants.dart';

class AddAnnouncementPage extends StatefulWidget {
  const AddAnnouncementPage({super.key});

  @override
  State<AddAnnouncementPage> createState() => _AddAnnouncementPageState();
}

class _AddAnnouncementPageState extends State<AddAnnouncementPage> {
  final DatabaseService _db = DatabaseService();
  String _message = '';

  Future<void> _showAddEditDialog({String? id, Map<String, dynamic>? data}) async {
    final titleCtrl = TextEditingController(text: data?['title'] ?? '');
    final descCtrl = TextEditingController(text: data?['description'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          id == null ? 'New Announcement' : 'Edit Announcement',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryBlack),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentGold, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Message',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentGold, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill title and message')),
                );
                return;
              }

              final announcementData = {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'created_at': FieldValue.serverTimestamp(),
              };

              try {
                if (id == null) {
                  await _db.addAnnouncement(announcementData);
                } else {
                  await _db.firestore.collection('announcements').doc(id).update(announcementData);
                }
                Navigator.pop(context);
                setState(() => _message = 'Announcement ${id == null ? 'posted' : 'updated'}');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGold,
              foregroundColor: primaryBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(id == null ? 'Post' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteAnnouncement(id);
      setState(() => _message = 'Announcement deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: Column(
        children: [

          // Success message
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _message.contains('deleted') ? errorRed.withOpacity(0.1) : successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _message.contains('deleted') ? errorRed : successGreen, width: 1),
                ),
                child: Text(_message, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),

          // New Announcement Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Announcement', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                foregroundColor: primaryBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Announcement List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: accentGold));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No announcements yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (_, i) {
                    final doc = snapshot.data!.docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(data['title'] ?? 'No title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(data['description'] ?? '', style: const TextStyle(fontSize: 15)),
                        ),
                        trailing: PopupMenuButton(
                          onSelected: (v) {
                            if (v == 'edit') _showAddEditDialog(id: doc.id, data: data);
                            if (v == 'delete') _delete(doc.id);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: errorRed))),
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
    );
  }
}