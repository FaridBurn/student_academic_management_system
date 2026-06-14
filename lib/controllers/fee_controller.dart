import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/fee.dart';
import '../models/payment.dart';
import '../services/supabase_fee_service.dart';
import '../services/stripe_service.dart';

enum FeeState { idle, loading, loaded, error }
enum PaymentState { idle, processing, success, failed, cancelled }

class FeeController extends ChangeNotifier {
  FeeState feeState = FeeState.idle;
  PaymentState paymentState = PaymentState.idle;

  Fee? currentFee;
  List<Payment> paymentHistory = [];
  String? errorMessage;
  String? transactionRef;

  Future<void> requestFeeDetails(String studentId) async {
    feeState = FeeState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      currentFee = await SupabaseFeeService.getFeeForStudent(studentId);
      feeState = currentFee != null ? FeeState.loaded : FeeState.error;
      if (currentFee == null) errorMessage = 'No fee record found.';
    } catch (e) {
      errorMessage = 'Failed to load fee details. Please try again.\n$e';
      feeState = FeeState.error;
    }

    notifyListeners();
  }

  Future<void> processPayment({required String studentId}) async {
    if (currentFee == null) return;

    paymentState = PaymentState.processing;
    errorMessage = null;
    notifyListeners();

    try {
      final ref = await StripeService.makePayment(
        amount: currentFee!.totalFee,
        feeId: currentFee!.feeId,
        studentId: studentId,
      );

      transactionRef = ref;

      await SupabaseFeeService.savePayment(Payment(
        feeId: currentFee!.feeId,
        studentId: studentId,
        amount: currentFee!.totalFee,
        paymentMethod: 'Stripe',
        transactionRef: ref,
        status: 'Success',
      ));

      await SupabaseFeeService.updateFeeStatus(
          currentFee!.feeId, 'Paid', paidAmount: currentFee!.totalFee);
      await SupabaseFeeService.updateStudentBlockStatus(studentId, false);

      currentFee!.status = 'Paid';
      paymentState = PaymentState.success;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        paymentState = PaymentState.cancelled;
        await _logFailedPayment(studentId, 'Cancelled');
      } else {
        errorMessage = e.error.localizedMessage ?? 'Payment failed.';
        paymentState = PaymentState.failed;
        await _logFailedPayment(studentId, 'Failed');
      }
    } catch (e) {
      errorMessage = 'An unexpected error occurred: $e';
      paymentState = PaymentState.failed;
    }

    notifyListeners();
  }

  Future<void> _logFailedPayment(String studentId, String status) async {
    if (currentFee == null) return;
    try {
      await SupabaseFeeService.savePayment(Payment(
        feeId: currentFee!.feeId,
        studentId: studentId,
        amount: currentFee!.totalFee,
        paymentMethod: 'Stripe',
        transactionRef: null,
        status: status,
      ));
    } catch (_) {}
  }

  Future<bool> checkOverdueAndBlock(String studentId) async {
    if (currentFee == null || !currentFee!.isOverdue()) return false;

    try {
      await SupabaseFeeService.updateStudentBlockStatus(studentId, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> getPaymentHistory(String studentId) async {
    try {
      paymentHistory = await SupabaseFeeService.getPaymentHistory(studentId);
      notifyListeners();
    } catch (_) {}
  }

  void resetPaymentState() {
    paymentState = PaymentState.idle;
    errorMessage = null;
    transactionRef = null;
    notifyListeners();
  }
}
