class Registration {
  final int registrationID;
  final int studentID;
  final int subjectID;
  final String semester;
  final String academicYear;
  final String status;
  final DateTime registeredAt;
  final DateTime? updatedAt;

  Registration({
    required this.registrationID,
    required this.studentID,
    required this.subjectID,
    required this.semester,
    required this.academicYear,
    required this.status,
    required this.registeredAt,
    this.updatedAt,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      registrationID: json['registrationid'],
      studentID: json['studentid'],
      subjectID: json['subjectid'],
      semester: json['semester'],
      academicYear: json['academic_year'],
      status: json['status'],
      registeredAt: DateTime.parse(json['registered_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registrationid': registrationID,
      'studentid': studentID,
      'subjectid': subjectID,
      'semester': semester,
      'academic_year': academicYear,
      'status': status,
      'registered_at': registeredAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}