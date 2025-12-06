import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_attendance_app/services/database_service.dart';
import 'package:simple_attendance_app/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AddSeminarPage extends StatefulWidget {
  const AddSeminarPage({super.key});

  @override
  _AddSeminarPageState createState() => _AddSeminarPageState();
}

class _AddSeminarPageState extends State<AddSeminarPage> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String _title = '';
  String _description = '';
  String _presenter = '';
  String _advisor = '';
  String _videoLink = '';
  DateTime _selectedDate = DateTime.now();
  int _maxAttendees = 0;
  String _message = '';

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: accentGold,
            onPrimary: primaryBlack,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // PRINT QR CODE
  Future<void> _printQRCode(String seminarId, String title, String shortCode) async {
    final pdf = pw.Document();
    final qrImage = await QrPainter(
      data: seminarId,
      version: QrVersions.auto,
      gapless: false,
      color: primaryBlack,
      emptyColor: backgroundWhite,
    ).toImageData(300);

    if (qrImage == null) return;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('SEMINAR QR CODE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Code: $shortCode', style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Image(pw.MemoryImage(qrImage.buffer.asUint8List()), width: 250, height: 250),
            ),
            pw.SizedBox(height: 24),
            pw.Text('Scan to check in', style: const pw.TextStyle(fontSize: 14)),
            pw.Spacer(),
            pw.Text('Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _showQRDialog(String id, String title, String code) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlack)),
              const SizedBox(height: 20),
              QrImageView(data: id, size: 200, backgroundColor: Colors.white),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: accentGold.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(code, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: accentGold)),
              ),
              const SizedBox(height: 12),
              Text('Students scan or enter this code', style: TextStyle(color: primaryBlack.withOpacity(0.7))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print, color: primaryBlack),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: primaryBlack),
                    onPressed: () {
                      Navigator.pop(context);
                      _printQRCode(id, title, code);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy, color: primaryBlack),
                    label: const Text('Copy Code'),
                    style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: primaryBlack),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code copied: $code')));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: primaryBlack))),
            ],
          ),
        ),
      ),
    );
  }

  // ADD / EDIT DIALOG
  Future<void> _showAddEditDialog({String? id, Map<String, dynamic>? data}) async {
    _title = data?['title'] ?? '';
    _description = data?['description'] ?? '';
    _presenter = data?['presenter'] ?? '';
    _advisor = data?['advisor'] ?? '';
    _videoLink = data?['video_link'] ?? '';
    _selectedDate = (data?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    _maxAttendees = data?['max_attendees'] ?? 0;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(id == null ? 'Add Seminar' : 'Edit Seminar',
            style: TextStyle(color: primaryBlack, fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Seminar Title *', _title, (v) => _title = v, validator: (v) => v!.isEmpty ? 'Required' : null),
                _field('Presenter Name *', _presenter, (v) => _presenter = v, validator: (v) => v!.isEmpty ? 'Required' : null),
                _field('Advisor Name', _advisor, (v) => _advisor = v),
                _field('Description *', _description, (v) => _description = v, maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
                _field('Video Link', _videoLink, (v) => _videoLink = v),

                const SizedBox(height: 16),
                _dateTile('Seminar Date', _selectedDate, _selectDate),

                const SizedBox(height: 16),
                _field('Max Attendees (0 = unlimited)', _maxAttendees > 0 ? _maxAttendees.toString() : '',
                    (v) => _maxAttendees = int.tryParse(v) ?? 0, keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: primaryBlack))),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: primaryBlack),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: primaryBlack),
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              final seminarData = {
                'title': _title.trim(),
                'description': _description.trim(),
                'presenter': _presenter.trim(),
                'advisor': _advisor.trim().isEmpty ? null : _advisor.trim(),
                'video_link': _videoLink.trim().isEmpty ? null : _videoLink.trim(),
                'date': Timestamp.fromDate(_selectedDate),
                'max_attendees': _maxAttendees,
                'attendance_open_manual': true,
                'feedback_open_manual': true,
              };

              try {
                if (id == null) {
                  final result = await _db.addSeminar(seminarData);
                  final seminarId = result['id']!;
                  final shortCode = result['shortCode']!;
                  Navigator.pop(context);
                  _showQRDialog(seminarId, _title, shortCode);
                  setState(() => _message = 'Seminar created! Code: $shortCode');
                } else {
                  await _db.firestore.collection('seminars').doc(id).update(seminarData);
                  Navigator.pop(context);
                  setState(() => _message = 'Seminar updated successfully!');
                }
              } catch (e) {
                setState(() => _message = 'Error: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  // UI WIDGETS
  Widget _field(String label, String init, Function(String) onChange,
      {int maxLines = 1, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: init,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(_iconFor(label), color: accentGold),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentGold, width: 2)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChange,
      ),
    );
  }

  IconData _iconFor(String label) {
    if (label.contains('Title')) return Icons.title;
    if (label.contains('Presenter')) return Icons.person;
    if (label.contains('Advisor')) return Icons.school;
    if (label.contains('Description')) return Icons.description;
    if (label.contains('Video')) return Icons.link;
    if (label.contains('Attendees')) return Icons.group;
    return Icons.info;
  }

  Widget _dateTile(String label, DateTime date, Future<void> Function() onTap) {
    return ListTile(
      leading: Icon(Icons.calendar_today, color: accentGold),
      title: Text('$label: ${DateFormat('dd/MM/yyyy').format(date)}'),
      trailing: Icon(Icons.edit, color: accentGold),
      tileColor: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }

  Future<void> _toggleManual(String id, String field, bool value) async {
    await _db.firestore.collection('seminars').doc(id).update({field: value});
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Seminar?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: errorRed), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteSeminar(id);
      setState(() => _message = 'Seminar deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: primaryBlack,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: accentGold), onPressed: () => Navigator.pop(context)),
        title: const Text('Seminars', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seminars', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryBlack)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: primaryBlack),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: primaryBlack),
                  onPressed: () => _showAddEditDialog(),
                ),
              ],
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.contains('success') || _message.contains('created') ? successGreen.withOpacity(0.1) : errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _message.contains('success') || _message.contains('created') ? successGreen : errorRed),
                ),
                child: Row(children: [
                  Icon(_message.contains('success') || _message.contains('created') ? Icons.check_circle : Icons.error,
                      color: _message.contains('success') || _message.contains('created') ? successGreen : errorRed),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_message)),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('seminars').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: accentGold));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event, size: 80, color: primaryBlack.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text('No seminars yet', style: TextStyle(fontSize: 18, color: primaryBlack)),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, color: primaryBlack),
                            label: const Text('Create First Seminar'),
                            style: ElevatedButton.styleFrom(backgroundColor: accentGold),
                            onPressed: () => _showAddEditDialog(),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (_, i) {
                      final doc = snapshot.data!.docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'Untitled';
                      final code = data['attendance_code_short'] ?? 'N/A';
                      final attOpen = data['attendance_open_manual'] ?? true;
                      final fbOpen = data['feedback_open_manual'] ?? true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlack)),
                                        Text('Presenter: ${data['presenter'] ?? '—'}', style: TextStyle(color: primaryBlack.withOpacity(0.7))),
                                        Text('Code: $code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentGold, letterSpacing: 2)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'qr') _showQRDialog(doc.id, title, code);
                                      if (v == 'edit') _showAddEditDialog(id: doc.id, data: data);
                                      if (v == 'delete') _delete(doc.id);
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'qr', child: Row(children: [Icon(Icons.qr_code), SizedBox(width: 8), Text('Show QR')])),
                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: errorRed), SizedBox(width: 8), Text('Delete')])),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Switch(value: attOpen, activeThumbColor: successGreen, onChanged: (v) => _toggleManual(doc.id, 'attendance_open_manual', v)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Switch(value: fbOpen, activeThumbColor: successGreen, onChanged: (v) => _toggleManual(doc.id, 'feedback_open_manual', v)),
                                      ],
                                    ),
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