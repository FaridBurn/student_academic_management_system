import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee.dart';
import '../models/payment.dart';

class SupabaseFeeService {
  static final _db = Supabase.instance.client;

  // ── Student ──────────────────────────────────────────────────

  static Future<Fee?> getFeeForStudent(String studentId) async {
    final data = await _db
        .from('tuition_fees')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return Fee.fromMap(data);
  }

  static Future<void> savePayment(Payment payment) async {
    await _db.from('payments').insert(payment.toMap());
  }

  /// Marks fee as Paid/Unpaid and keeps paid_amount in sync.
  static Future<void> updateFeeStatus(
      int feeId, String status, {double? paidAmount}) async {
    final update = <String, dynamic>{'status': status};
    if (paidAmount != null) update['paid_amount'] = paidAmount;
    await _db.from('tuition_fees').update(update).eq('fee_id', feeId);
  }

  static Future<void> updateStudentBlockStatus(
      String studentId, bool isBlocked) async {
    await _db
        .from('profiles')
        .update({'is_blocked': isBlocked})
        .eq('id', studentId);
  }

  static Future<List<Payment>> getPaymentHistory(String studentId) async {
    final data = await _db
        .from('payments')
        .select()
        .eq('student_id', studentId)
        .order('payment_date', ascending: false);

    return (data as List)
        .map((e) => Payment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ── Treasury: fee records ────────────────────────────────────

  static Future<void> createFeeRecord({
    required String studentId,
    required String semester,
    required String academicYear,
    required double totalFee,
    required DateTime dueDate,
  }) async {
    String p(int n) => n.toString().padLeft(2, '0');
    await _db.from('tuition_fees').insert({
      'student_id': studentId,
      'semester': semester,
      'academic_year': academicYear,
      'total_fee': totalFee,
      'paid_amount': 0,
      'due_date':
          '${dueDate.year}-${p(dueDate.month)}-${p(dueDate.day)}',
      'status': 'Unpaid',
    });
  }

  static Future<List<Map<String, dynamic>>> getAllFeesWithProfiles() async {
    final fees = await _db
        .from('tuition_fees')
        .select(
            'fee_id, student_id, semester, academic_year, total_fee, paid_amount, due_date, status, created_at')
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> result = [];
    for (final fee in fees as List) {
      final profile = await _db
          .from('profiles')
          .select('name, email, phone')
          .eq('id', fee['student_id'])
          .maybeSingle();
      result.add({
        ...fee,
        'name': profile?['name'] ?? 'Unknown',
        'email': profile?['email'] ?? '',
        'phone': profile?['phone'] ?? '',
      });
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> getAllStudentProfiles() async {
    final data = await _db
        .from('profiles')
        .select('id, name, email, programme, batch')
        .eq('role', 'student')
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Treasury: payments ───────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllPaymentsWithProfiles() async {
    final payments = await _db
        .from('payments')
        .select(
            'payment_id, fee_id, student_id, amount, payment_method, transaction_ref, payment_date, status')
        .order('payment_date', ascending: false);

    final List<Map<String, dynamic>> result = [];
    for (final p in payments as List) {
      final profile = await _db
          .from('profiles')
          .select('name, email')
          .eq('id', p['student_id'])
          .maybeSingle();
      result.add({
        ...p,
        'name': profile?['name'] ?? 'Unknown',
        'email': profile?['email'] ?? '',
      });
    }
    return result;
  }

  /// Updates payment status AND syncs tuition_fees.status accordingly.
  /// Approve → tuition_fees stays Paid.
  /// Reject  → tuition_fees reset to Unpaid + paid_amount = 0.
  static Future<void> updatePaymentAndFeeStatus({
    required int paymentId,
    required int feeId,
    required String newPaymentStatus,
  }) async {
    await _db
        .from('payments')
        .update({'status': newPaymentStatus})
        .eq('payment_id', paymentId);

    if (newPaymentStatus == 'Failed') {
      await _db.from('tuition_fees').update({
        'status': 'Unpaid',
        'paid_amount': 0,
      }).eq('fee_id', feeId);
    }
  }

  // ── Treasury: blocked students ───────────────────────────────

  static Future<List<Map<String, dynamic>>> getBlockedStudents() async {
    final data = await _db
        .from('profiles')
        .select('id, name, email, phone, programme, batch')
        .eq('role', 'student')
        .eq('is_blocked', true);
    return List<Map<String, dynamic>>.from(data as List);
  }
}
