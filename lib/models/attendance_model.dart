class AttendanceModel {
  final String id;
  final String seminarId;
  final String userId;
  final String email;
  final String attendanceCode;
  final DateTime loginDate;
  final String loginTime;

  AttendanceModel({
    required this.id,
    required this.seminarId,
    required this.userId,
    required this.email,
    required this.attendanceCode,
    required this.loginDate,
    required this.loginTime,
  });
}