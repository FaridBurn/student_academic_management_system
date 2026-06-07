class UserModel {
  final String id;
  final String name;
  final String role;
  final String? studentId;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.studentId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      role: map['role'],
      studentId: map['student_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'student_id': studentId,
    };
  }
}