class CurriculumActivityModel {
  final int id;
  final String name;
  final String? category;
  final int hours;

  CurriculumActivityModel({
    required this.id,
    required this.name,
    this.category,
    required this.hours,
  });

  factory CurriculumActivityModel.fromMap(Map<String, dynamic> map) {
    return CurriculumActivityModel(
      id: map['id'] as int,
      name: map['name'] ?? '',
      category: map['category'],
      hours: map['hours'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'hours': hours,
    };
  }
}

class CurriculumClaimModel {
  final String id;
  final String studentId;
  final String activityId;
  final String status;
  final DateTime claimedAt;

  CurriculumClaimModel({
    required this.id,
    required this.studentId,
    required this.activityId,
    required this.status,
    required this.claimedAt,
  });

  factory CurriculumClaimModel.fromMap(Map<String, dynamic> map) {
    return CurriculumClaimModel(
      id: map['id'],
      studentId: map['student_id'],
      activityId: map['activity_id'],
      status: map['status'],
      claimedAt: DateTime.parse(map['claimed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'activity_id': activityId,
      'status': status,
      'claimed_at': claimedAt.toIso8601String(),
    };
  }
}