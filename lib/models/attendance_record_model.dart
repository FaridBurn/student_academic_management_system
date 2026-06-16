class AttendanceRecordModel {
  final int attendanceId;
  final int sessionId;
  final String studentId;
  final DateTime checkInTime;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final bool isVerified;

  AttendanceRecordModel({
    required this.attendanceId,
    required this.sessionId,
    required this.studentId,
    required this.checkInTime,
    this.gpsLatitude,
    this.gpsLongitude,
    required this.isVerified,
  });

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> data) {
    return AttendanceRecordModel(
      attendanceId: data['attendance_id'] as int,
      sessionId: data['session_id'] as int,
      studentId: data['student_id'] as String,
      checkInTime: DateTime.parse(data['check_in_time'] as String),
      gpsLatitude: (data['gps_latitude'] as num?)?.toDouble(),
      gpsLongitude: (data['gps_longitude'] as num?)?.toDouble(),
      isVerified: data['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'student_id': studentId,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'is_verified': isVerified,
    };
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55
