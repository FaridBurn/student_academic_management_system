class AttendanceCodeModel {
  final String id;
  final String subjectId;
  final String lecturerId;
  final String code;
  final DateTime createdAt;
  final DateTime? expiresAt;

  AttendanceCodeModel({
    required this.id,
    required this.subjectId,
    required this.lecturerId,
    required this.code,
    required this.createdAt,
    this.expiresAt,
  });

  factory AttendanceCodeModel.fromMap(Map<String, dynamic> map) {
    return AttendanceCodeModel(
      id: map['id'],
      subjectId: map['subject_id'],
      lecturerId: map['lecturer_id'],
      code: map['code'],
      createdAt: DateTime.parse(map['created_at']),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'lecturer_id': lecturerId,
      'code': code,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

class AttendanceModel {
  final String id;
  final String studentId;
  final String subjectId;
  final String codeId;
  final String status;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.codeId,
    required this.status,
    required this.createdAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'],
      studentId: map['student_id'],
      subjectId: map['subject_id'],
      codeId: map['code_id'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'subject_id': subjectId,
      'code_id': codeId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}