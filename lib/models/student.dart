class Student {
  final int studentID;
  final String stu_name;
  final String stu_email;
  final String stu_password;
  final String stu_number;
  final String stu_programme;
  final String stu_batch;
  final bool stu_blocked;

  Student({
    required this.studentID,
    required this.stu_name,
    required this.stu_email,
    required this.stu_password,
    required this.stu_number,
    required this.stu_programme,
    required this.stu_batch,
    required this.stu_blocked,
  });

<<<<<<< HEAD
factory Student.fromJson(Map<String, dynamic> json) {
  // Handle both 'studentID' and 'studentid'
  final id = json['studentID'] ?? json['studentid'];
  return Student(
    studentID: id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0,
    stu_name: json['stu_name'] ?? '',
    stu_email: json['stu_email'] ?? '',
    stu_password: json['stu_password'] ?? '',
    stu_number: json['stu_number'] ?? '',
    stu_programme: json['stu_programme'] ?? '',
    stu_batch: json['stu_batch'] ?? '',
    stu_blocked: json['stu_blocked'] ?? false,
  );
}
=======
  factory Student.fromJson(Map<String, dynamic> json) {
    // Handle both 'studentID' and 'studentid' (Supabase returns lowercase)
    final id = json['studentID'] ?? json['studentid'];

    return Student(
      studentID: id is int ? id : int.tryParse(id.toString()) ?? 0,
      stu_name: json['stu_name'],
      stu_email: json['stu_email'],
      stu_password: json['stu_password'],
      stu_number: json['stu_number'],
      stu_programme: json['stu_programme'],
      stu_batch: json['stu_batch'],
      stu_blocked: json['stu_blocked'] ?? false,
    );
  }
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55

  Map<String, dynamic> toJson() {
    return {
      'studentID': studentID,
      'stu_name': stu_name,
      'stu_email': stu_email,
      'stu_password': stu_password,
      'stu_number': stu_number,
      'stu_programme': stu_programme,
      'stu_batch': stu_batch,
      'stu_blocked': stu_blocked,
    };
  }
}