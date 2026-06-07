class SubjectModel {
  final String id;
  final String code;
  final String name;
  final int creditHours;
  final String? lecturerId;
  final String? semester;

  SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.creditHours,
    this.lecturerId,
    this.semester,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      creditHours: map['credit_hours'],
      lecturerId: map['lecturer_id'],
      semester: map['semester'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'credit_hours': creditHours,
      'lecturer_id': lecturerId,
      'semester': semester,
    };
  }
}