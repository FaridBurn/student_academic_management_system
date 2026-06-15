class Payment {
  final int? paymentId;
  final int feeId;
  final String studentId;
  final double amount;
  final String paymentMethod;
  final String? transactionRef;
  String status;
  final DateTime? paymentDate;

  Payment({
    this.paymentId,
    required this.feeId,
    required this.studentId,
    required this.amount,
    required this.paymentMethod,
    this.transactionRef,
    required this.status,
    this.paymentDate,
  });

  factory Payment.fromMap(Map<String, dynamic> data) {
    return Payment(
      paymentId: data['payment_id'] as int?,
      feeId: data['fee_id'] as int,
      studentId: data['student_id'] as String,
      amount: (data['amount'] as num).toDouble(),
      paymentMethod: data['payment_method'] as String,
      transactionRef: data['transaction_ref'] as String?,
      status: data['status'] as String,
      paymentDate: data['payment_date'] != null
          ? DateTime.parse(data['payment_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fee_id': feeId,
      'student_id': studentId,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_ref': transactionRef,
      'status': status,
    };
  }
}
