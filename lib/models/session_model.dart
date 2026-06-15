class SessionModel {
  final int sessionId;
  final String lecturerId;
  final String subjectCode;
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final String attendanceCode;
  final bool isActive;
  final DateTime createdAt;

  SessionModel({
    required this.sessionId,
    required this.lecturerId,
    required this.subjectCode,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.attendanceCode,
    required this.isActive,
    required this.createdAt,
  });

  factory SessionModel.fromMap(Map<String, dynamic> data) {
    return SessionModel(
      sessionId: data['session_id'] as int,
      lecturerId: data['lecturer_id'] as String,
      subjectCode: data['subject_code'] as String,
      sessionDate: DateTime.parse(data['session_date'] as String),
      startTime: data['start_time'] as String,
      endTime: data['end_time'] as String,
      attendanceCode: data['attendance_code'] as String,
      isActive: data['is_active'] as bool,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lecturer_id': lecturerId,
      'subject_code': subjectCode,
      'session_date':
          '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'end_time': endTime,
      'attendance_code': attendanceCode,
      'is_active': isActive,
    };
  }
}
