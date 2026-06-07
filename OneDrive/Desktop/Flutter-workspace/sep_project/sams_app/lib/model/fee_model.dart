class FeeModel {
  final String id;
  final String studentId;
  final double amount;
  final String? semester;
  final String status;
  final DateTime? dueDate;
  final DateTime? paidAt;

  FeeModel({
    required this.id,
    required this.studentId,
    required this.amount,
    this.semester,
    required this.status,
    this.dueDate,
    this.paidAt,
  });

  factory FeeModel.fromMap(Map<String, dynamic> map) {
    return FeeModel(
      id: map['id'],
      studentId: map['student_id'],
      amount: (map['amount'] as num).toDouble(),
      semester: map['semester'],
      status: map['status'],
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'])
          : null,
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'semester': semester,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}