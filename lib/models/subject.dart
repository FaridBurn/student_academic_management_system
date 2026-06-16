class Subject {
  final int subjectID;
  final String sub_code;
  final String sub_name;
  final int credit_hours;
  final String sub_semester;

  Subject({
    required this.subjectID,
    required this.sub_code,
    required this.sub_name,
    required this.credit_hours,
    required this.sub_semester,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    // Handle both 'subjectID' and 'subjectid'
    final id = json['subjectID'] ?? json['subjectid'];
  
    return Subject(
      subjectID: id is int ? id : int.tryParse(id.toString()) ?? 0,
      sub_code: json['sub_code'],
      sub_name: json['sub_name'],
      credit_hours: json['credit_hours'],
      sub_semester: json['sub_semester'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectID': subjectID,
      'sub_code': sub_code,
      'sub_name': sub_name,
      'credit_hours': credit_hours,
      'sub_semester': sub_semester,
    };
  }
}