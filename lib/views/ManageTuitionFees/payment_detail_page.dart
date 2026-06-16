import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/fee_controller.dart';
import 'payment_confirmation_prompt.dart';

class PaymentDetailPage extends StatefulWidget {
  final String studentUid;

  const PaymentDetailPage({super.key, required this.studentUid});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  void _navigateToConfirmation() {
    final fee = context.read<FeeController>().currentFee;
    if (fee == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentConfirmationPrompt(
        studentUid: widget.studentUid,
        feeAmount: fee.totalFee,
        semester: fee.semester,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fee = context.watch<FeeController>().currentFee;
    final currencyFmt =
        NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A6B),
        foregroundColor: Colors.white,
        title: const Text('Make Payment',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: fee == null
          ? const Center(child: Text('No fee record loaded.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Fee summary card ─────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fee Details',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        _DetailRow(label: 'Semester', value: fee.semester),
                        _DetailRow(
                            label: 'Academic Year', value: fee.academicYear),
                        _DetailRow(
                          label: 'Amount Due',
                          value: currencyFmt.format(fee.totalFee),
                          valueStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A6B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text('Payment Method',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF635BFF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF635BFF).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF635BFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.credit_card,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stripe',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              Text(
                                'Credit/Debit Card · FPX · e-Wallets',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle,
                            color: Color(0xFF635BFF)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: Color(0xFF1A3A6B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will be redirected to a secure Stripe payment sheet. '
                            'Your card details are handled by Stripe and never stored on SAMS servers.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF635BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.lock_outline),
                      label: Text(
                        'Pay ${currencyFmt.format(fee.totalFee)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _navigateToConfirmation,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'Secured by Stripe  🔒',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow(
      {required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style: valueStyle ??
                  const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}