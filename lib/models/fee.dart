class Fee {
  final int feeId;
  final String studentId;
  final String semester;
  final String academicYear;
  final double totalFee;
  final double paidAmount;
  final DateTime dueDate;
  String status;
  final DateTime createdAt;

  Fee({
    required this.feeId,
    required this.studentId,
    required this.semester,
    required this.academicYear,
    required this.totalFee,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory Fee.fromMap(Map<String, dynamic> data) {
    return Fee(
      feeId: data['fee_id'] as int,
      studentId: data['student_id'] as String,
      semester: data['semester'] as String,
      academicYear: data['academic_year'] as String,
      totalFee: (data['total_fee'] as num).toDouble(),
      paidAmount: (data['paid_amount'] as num? ?? 0).toDouble(),
      dueDate: DateTime.parse(data['due_date'] as String),
      status: data['status'] as String,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'semester': semester,
      'academic_year': academicYear,
      'total_fee': totalFee,
      'due_date': dueDate.toIso8601String(),
      'status': status,
    };
  }

  bool isPaid() => status == 'Paid';

  bool isOverdue() =>
      status == 'Unpaid' && DateTime.now().isAfter(dueDate);
}
