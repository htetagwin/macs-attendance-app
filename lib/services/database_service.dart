import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_attendance_app/models/attendance_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseFirestore get firestore => _firestore;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  // Generate UNIQUE 5-character short code
  Future<String> _generateUniqueShortCode() async {
    final random = Random();
    const maxAttempts = 30;

    for (int i = 0; i < maxAttempts; i++) {
      final code = List.generate(
        5,
        (_) => _chars[random.nextInt(_chars.length)],
      ).join();

      final snap = await _firestore
          .collection('seminars')
          .where('attendance_code_short', isEqualTo: code)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return code;
    }
    return List.generate(
      5,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
  }

  // ADD SEMINAR
  Future<Map<String, String>> addSeminar(
    Map<String, dynamic> seminarData,
  ) async {
    final shortCode = await _generateUniqueShortCode();
    final seminarRef = _firestore.collection('seminars').doc();
    final seminarId = seminarRef.id;
    final fullCode = 'seminar_${seminarId}_$shortCode';

    await seminarRef.set({
      ...seminarData,
      'seminar_id': seminarId,
      'attendance_code': fullCode,
      'attendance_code_short': shortCode,
      'attendance_open_manual': true,
      'feedback_open_manual': true,
      'created_at': FieldValue.serverTimestamp(),
    });

    return {'id': seminarId, 'shortCode': shortCode};
  }

  // REGENERATE CODE
  Future<void> regenerateAttendanceCode(String seminarId) async {
    final shortCode = await _generateUniqueShortCode();
    final fullCode = 'seminar_${seminarId}_$shortCode';

    await _firestore.collection('seminars').doc(seminarId).update({
      'attendance_code': fullCode,
      'attendance_code_short': shortCode,
      'code_updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> recordAttendance(AttendanceModel attendance) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Fetch both seminar and user data in parallel
      final seminarFuture = _firestore
          .collection('seminars')
          .doc(attendance.seminarId)
          .get();
      final userFuture = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final results = await Future.wait([seminarFuture, userFuture]);
      final seminarDoc = results[0] as DocumentSnapshot;
      final userDoc = results[1] as DocumentSnapshot;

      if (!seminarDoc.exists) throw Exception('Seminar not found');

      final seminarData = seminarDoc.data() as Map<String, dynamic>;
      final bool isOpen = seminarData['attendance_open_manual'] ?? true;
      if (!isOpen) throw Exception('Attendance is closed by admin');

      final storedShort = (seminarData['attendance_code_short'] as String)
          .toUpperCase();
      if (storedShort != attendance.attendanceCode.toUpperCase()) {
        throw Exception('Invalid code');
      }

      // Max attendees check
      final max = seminarData['max_attendees'] as int? ?? 0;
      if (max > 0) {
        final countSnap = await _firestore
            .collection('attendance')
            .where('seminar_id', isEqualTo: attendance.seminarId)
            .get();
        if (countSnap.docs.length >= max) throw Exception('Seminar is full');
      }

      // Prevent duplicate
      final attendanceDocId = '${attendance.seminarId}_${currentUser.uid}';
      final existing = await _firestore
          .collection('attendance')
          .doc(attendanceDocId)
          .get();
      if (existing.exists) throw Exception('You have already checked in');

      // Extract denormalized data
      final String seminarTitle =
          (seminarData['title'] as String?)?.trim() ?? 'Unknown Seminar';

      String studentName = currentUser.email?.split('@').first ?? 'Student';
      String userRole = 'student'; // default

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final first = (userData['first_name'] as String?)?.trim() ?? '';
        final last = (userData['last_name'] as String?)?.trim() ?? '';
        final full = '$first $last'.trim();
        if (full.isNotEmpty) studentName = full;

        userRole = (userData['role'] as String?)?.toLowerCase() ?? 'student';
      }

      // Save attendance with rich, readable data
      await _firestore.collection('attendance').doc(attendanceDocId).set({
        'seminar_id': attendance.seminarId,
        'seminar_title': seminarTitle, // ← NEW: Full title
        'user_id': currentUser.uid,
        'student_name': studentName, // ← NEW: Full name
        'email': currentUser.email ?? 'unknown@email.com',
        'user_role': userRole, // ← NEW: Role (student/admin)

        'code_used': attendance.attendanceCode,
        'attendance_code_full':
            'seminar_${attendance.seminarId}_${attendance.attendanceCode}',

        'login_date': Timestamp.fromDate(attendance.loginDate),
        'login_time': attendance.loginTime,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Attendance Error: $e");
      rethrow;
    }
  }

  // TOGGLE ATTENDANCE
  Future<void> toggleAttendanceAcceptance(
    String seminarId,
    bool current,
  ) async {
    await _firestore.collection('seminars').doc(seminarId).update({
      'attendance_open_manual': !current,
    });
  }

  // DELETE SEMINAR
  Future<void> deleteSeminar(String seminarId) async {
    await _firestore.collection('seminars').doc(seminarId).delete();
  }

  // ADD ANNOUNCEMENT – FIXED & SAFE
  Future<String> addAnnouncement(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection('announcements').add(data);
      print('Announcement added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding announcement: $e');
      rethrow;
    }
  }

  // DELETE ANNOUNCEMENT
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).delete();
      print('Announcement deleted: $announcementId');
    } catch (e) {
      print('Error deleting announcement: $e');
      rethrow;
    }
  }

  // ADMIN USER MANAGEMENT
  Future<String?> addUser(String email, String password, String role) async {
    UserCredential? cred;
    try {
      await _ensureAdmin();

      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });

      return 'User added successfully';
    } on FirebaseAuthException catch (e) {
      _cleanupUser(cred);
      return switch (e.code) {
        'email-already-in-use' => 'Email already in use.',
        'weak-password' => 'Password too weak.',
        'invalid-email' => 'Invalid email.',
        _ => 'Auth error: ${e.message}',
      };
    } catch (e) {
      _cleanupUser(cred);
      return 'Error: $e';
    }
  }

  Future<String?> updateUserRole(String userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    try {
      await _ensureAdmin();
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return 'Role updated to $newRole';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> deleteUser(String userId) async {
    try {
      await _ensureAdmin();
      await _firestore.collection('users').doc(userId).delete();
      return 'User deleted';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // PRIVATE HELPERS
  Future<void> _ensureAdmin() async {
    if (_auth.currentUser == null) throw Exception('Not logged in');
    final doc = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    if (!doc.exists || doc['role'] != 'admin')
      throw Exception('Admin access required');
  }

  void _cleanupUser(UserCredential? cred) {
    cred?.user?.delete().catchError((_) {});
  }
}
