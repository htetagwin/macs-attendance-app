import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:simple_attendance_app/constants.dart';
import 'package:simple_attendance_app/services/database_service.dart';
import 'package:simple_attendance_app/models/attendance_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SeminarDetailPage extends StatefulWidget {
  final String seminarId;
  const SeminarDetailPage({super.key, required this.seminarId});

  @override
  _SeminarDetailPageState createState() => _SeminarDetailPageState();
}

class _SeminarDetailPageState extends State<SeminarDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  Map<String, dynamic>? _seminar;
  bool _isLoading = true;
  String _error = '';
  bool _hasTakenAttendance = false;
  bool _hasGivenFeedback = false;
  Map<String, int>? _userRatings;
  String? _shortCode;
  String? _userRole;

  bool _canCheckIn = false;
  bool _canGiveFeedback = false;
  String? _checkInMessage;
  String? _feedbackMessage;

  final TextEditingController _codeController = TextEditingController();
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _loadSeminarData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  //  LOAD SEMINAR + USER DATA
  Future<void> _loadSeminarData() async {
    try {
      setState(() => _isLoading = true);

      final seminarDoc = await _firestore.collection('seminars').doc(widget.seminarId).get();
      if (!seminarDoc.exists) {
        setState(() => _error = 'Seminar not found');
        return;
      }

      final data = seminarDoc.data()!;
      _shortCode = (data['attendance_code_short'] as String?)?.trim().toUpperCase();

      final now = DateTime.now();
      final seminarDate = (data['date'] as Timestamp).toDate();
      final presentationTime = data['presentation_time'] != null
          ? (data['presentation_time'] as Timestamp).toDate()
          : seminarDate;

      final attStart = data['attendance_start_time'] != null
          ? (data['attendance_start_time'] as Timestamp).toDate()
          : seminarDate.subtract(const Duration(hours: 1));
      final attEnd = data['attendance_end_time'] != null
          ? (data['attendance_end_time'] as Timestamp).toDate()
          : seminarDate.add(const Duration(hours: 2));

      final fbStart = data['feedback_start_time'] != null
          ? (data['feedback_start_time'] as Timestamp).toDate()
          : presentationTime;
      final fbEnd = data['feedback_end_time'] != null
          ? (data['feedback_end_time'] as Timestamp).toDate()
          : presentationTime.add(const Duration(hours: 24));

      final attOpenManual = data['attendance_open_manual'] ?? true;
      final fbOpenManual = data['feedback_open_manual'] ?? true;

      _canCheckIn = attOpenManual && now.isAfter(attStart) && now.isBefore(attEnd);
      _canGiveFeedback = fbOpenManual && now.isAfter(fbStart) && now.isBefore(fbEnd);

      _checkInMessage = attOpenManual
          ? (now.isBefore(attStart)
              ? 'Opens at ${DateFormat('h:mm a').format(attStart)}'
              : now.isAfter(attEnd)
                  ? 'Check-in closed'
                  : null)
          : 'Check-in disabled by admin';

      _feedbackMessage = fbOpenManual
          ? (now.isBefore(fbStart)
              ? 'Opens after presentation'
              : now.isAfter(fbEnd)
                  ? 'Feedback closed'
                  : null)
          : 'Feedback disabled by admin';

      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        _userRole = userDoc.data()?['role'] as String?;

        final attDoc = await _firestore
            .collection('attendance')
            .doc('${widget.seminarId}_${user.uid}')
            .get();
        _hasTakenAttendance = attDoc.exists;

        final fbDoc = await _firestore
            .collection('feedback')
            .doc('${widget.seminarId}_${user.uid}')
            .get();
        if (fbDoc.exists) {
          _hasGivenFeedback = true;
          final fbData = fbDoc.data()!;
          _userRatings = Map<String, int>.from(fbData['ratings'] ?? {});
        }
      }

      setState(() {
        _seminar = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load seminar';
        _isLoading = false;
      });
    }
  }

  //  VERIFY SHORT CODE (case-insensitive)
  bool _verifyShortCode(String input) {
    if (_shortCode == null) return false;
    return input.trim().toUpperCase() == _shortCode;
  }

  //  RECORD ATTENDANCE
  Future<void> _recordAttendance(String enteredCode, String method) async {
    final user = _auth.currentUser;
    if (user == null || _hasTakenAttendance || !_canCheckIn) return;

    final codeToSave = method == 'QR' ? _shortCode! : enteredCode.trim().toUpperCase();

    if (method == 'Code' && !_verifyShortCode(codeToSave)) {
      _showSnackBar('Invalid code', errorRed);
      return;
    }

    final model = AttendanceModel(
      id: '${widget.seminarId}_${user.uid}',
      seminarId: widget.seminarId,
      userId: user.uid,
      email: user.email!,
      attendanceCode: codeToSave,
      loginDate: DateTime.now(),
      loginTime: TimeOfDay.now().format(context),
    );

    try {
      await _db.recordAttendance(model);
      setState(() => _hasTakenAttendance = true);
      _showSnackBar('Attendance recorded!', successGreen);
    } catch (e) {
      _showSnackBar(e.toString(), errorRed);
    }
  }

  void _showSnackBar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  //  QR SCANNER
  void _showQRScanner() {
    if (!_canCheckIn || _hasTakenAttendance) return;

    _scannerController = MobileScannerController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: accentGold),
            SizedBox(width: 12),
            Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Align QR code within the frame'),
            SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue == widget.seminarId) {
                    _scannerController?.stop();
                    _recordAttendance('', 'QR');
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _scannerController?.stop();
              Navigator.pop(context);
            },
            child: Text('Cancel', style: TextStyle(color: primaryBlack)),
          ),
        ],
      ),
    ).then((_) {
      _scannerController?.dispose();
      _scannerController = null;
    });
  }

  //  MANUAL CODE ENTRY
  void _showManualCheckin() {
    if (!_canCheckIn || _hasTakenAttendance) return;
    _codeController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          backgroundColor: backgroundWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Enter 5-Character Code',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 5,
            decoration: InputDecoration(
              labelText: 'e.g. A1B2C',
              prefixIcon: const Icon(Icons.lock_outline, color: accentGold),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              counterText: '${_codeController.text.length}/5',
            ),
            onChanged: (_) => dialogSetState(() {}), // Critical: Rebuilds dialog
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: _codeController.text.length == 5
                  ? () async {
                      await _recordAttendance(_codeController.text, 'Code');
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  //  FEEDBACK DIALOG
  void _showFeedbackDialog() {
    if (!_canGiveFeedback || _hasGivenFeedback) return;

    final ratings = Map<String, int>.from(_userRatings ?? {
      'Introduction': 0, 'Content': 0, 'Flow': 0, 'Presentation': 0, 'Engagement': 0,
    });
    String comment = '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: backgroundWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rate the Seminar', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ...['Introduction', 'Content', 'Flow', 'Presentation', 'Engagement'].map((cat) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(cat, style: TextStyle(fontSize: 15)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) => GestureDetector(
                        onTap: () => setState(() => ratings[cat] = i + 1),
                        child: Icon(
                          i < ratings[cat]! ? Icons.star : Icons.star_border,
                          color: accentGold,
                          size: 24,
                        ),
                      )),
                    ),
                  );
                }),
                SizedBox(height: 12),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional comments (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onChanged: (v) => comment = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
              onPressed: ratings.values.every((r) => r > 0)
                  ? () async {
                      final user = _auth.currentUser!;
                      await _firestore.collection('feedback').doc('${widget.seminarId}_${user.uid}').set({
                        'seminar_id': widget.seminarId,
                        'user_id': user.uid,
                        'email': user.email,
                        'role': _userRole,
                        'ratings': ratings,
                        'feedback': comment,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                      this.setState(() {
                        _hasGivenFeedback = true;
                        _userRatings = ratings;
                      });
                      _showSnackBar('Thank you for your feedback!', successGreen);
                    }
                  : null,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  //  UI HELPERS
  Widget _infoRow(IconData icon, String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: accentGold, size: 20),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: isLink
                ? InkWell(
                    onTap: () => launchUrl(Uri.parse(value)),
                    child: Text(value, style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: primaryBlack),
        label: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryBlack,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  //  BUILD
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 600;
    final titleSize = isSmall ? 20.0 : 26.0;
    final padding = isSmall ? 16.0 : 24.0;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: accentGold)));
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: errorRed, size: 64),
              SizedBox(height: 16),
              Text(_error, style: TextStyle(color: errorRed, fontSize: 16)),
              ElevatedButton(onPressed: _loadSeminarData, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    final data = _seminar!;
    final date = (data['date'] as Timestamp).toDate();
    final presentationTime = data['presentation_time'] != null
        ? (data['presentation_time'] as Timestamp).toDate()
        : date;

    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: primaryBlack,
        title: Text('Seminar Details', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: titleSize)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accentGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seminar Info Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? 'No Title', style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: primaryBlack)),
                    SizedBox(height: 16),
                    if (data['presenter'] != null) _infoRow(Icons.person, 'Presenter', data['presenter']),
                    if (data['advisor'] != null) _infoRow(Icons.school, 'Advisor', data['advisor']),
                    _infoRow(Icons.event, 'Date', DateFormat('EEEE, MMM d, yyyy').format(date)),
                    _infoRow(Icons.access_time, 'Time', DateFormat('h:mm a').format(presentationTime)),
                    if (data['video_link']?.toString().isNotEmpty == true)
                      _infoRow(Icons.link, 'Recording', data['video_link'], isLink: true),
                    SizedBox(height: 16),
                    Text(data['description'] ?? 'No description available.', style: TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
            ),

            SizedBox(height: padding * 1.5),

            // Attendance Section
            Text('Attendance', style: TextStyle(fontSize: titleSize - 2, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            if (_hasTakenAttendance)
              _statusChip('Checked In', Icons.check_circle, successGreen)
            else if (!_canCheckIn)
              _statusChip(_checkInMessage!, Icons.schedule, Colors.orange)
            else ...[
              _actionButton('Scan QR Code', Icons.qr_code_scanner, _showQRScanner),
              SizedBox(height: 12),
              _actionButton('Enter Code Manually', Icons.lock_outline, _showManualCheckin),
            ],

            SizedBox(height: padding * 1.5),

            // Feedback Section
            Text('Feedback', style: TextStyle(fontSize: titleSize - 2, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            if (_hasGivenFeedback)
              _statusChip('Submitted', Icons.rate_review, successGreen)
            else if (!_canGiveFeedback)
              _statusChip(_feedbackMessage!, Icons.schedule, Colors.orange)
            else
              _actionButton('Give Feedback', Icons.rate_review, _showFeedbackDialog),
          ],
        ),
      ),
    );
  }
}