class ActivityClaimModel {
  final int id;
  final String status;
  final String? remark;
  final DateTime? joinedAt;
  final DateTime? claimedAt;
  final DateTime? createdAt;
  final String? profileId;
  final Map<String, dynamic>? curriculumActivities;
  final Map<String, dynamic>? profiles;

  ActivityClaimModel({
    required this.id,
    required this.status,
    this.remark,
    this.joinedAt,
    this.claimedAt,
    this.createdAt,
    this.profileId,
    this.curriculumActivities,
    this.profiles,
  });

  factory ActivityClaimModel.fromMap(Map<String, dynamic> map) {
    return ActivityClaimModel(
      id: map['id'],
      status: map['status'] ?? 'pending',
      remark: map['remark'],
      joinedAt: map['joined_at'] != null ? DateTime.tryParse(map['joined_at']) : null,
      claimedAt: map['claimed_at'] != null ? DateTime.tryParse(map['claimed_at']) : null,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      profileId: map['profile_id'],
      curriculumActivities: map['curriculum_activities'] as Map<String, dynamic>?,
      profiles: map['profiles'] as Map<String, dynamic>?,
    );
  }

  // Helper getters
  String get activityName {
    if (curriculumActivities != null) {
      return curriculumActivities!['name'] ?? 'Unknown Activity';
    }
    return 'Unknown Activity';
  }

  int get hours {
    if (curriculumActivities != null) {
      return curriculumActivities!['hours'] ?? 0;
    }
    return 0;
  }

  String get category {
    if (curriculumActivities != null) {
      return curriculumActivities!['category'] ?? 'General';
    }
    return 'General';
  }

  String get studentName {
    if (profiles != null) {
      return profiles!['name'] ?? 'Unknown Student';
    }
    return 'Unknown Student';
  }

  String get studentEmail {
    if (profiles != null) {
      return profiles!['email'] ?? '';
    }
    return '';
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isRegistered => status == 'registered';
}