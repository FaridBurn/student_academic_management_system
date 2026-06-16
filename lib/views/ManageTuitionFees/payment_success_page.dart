import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/fee_controller.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String transactionRef;
  final double amountPaid;

  const PaymentSuccessPage({
    super.key,
    required this.transactionRef,
    required this.amountPaid,
  });

  void _navigateToDashboard(BuildContext context) {
    context.read<FeeController>().resetPaymentState();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt =
        NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle,
                    size: 72, color: Colors.green[600]),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A6B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your tuition fee has been paid. '
                'Your academic access is now active.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 32),
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
                    const Text('Receipt',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 20),
                    _ReceiptRow(
                        label: 'Amount Paid',
                        value: currencyFmt.format(amountPaid),
                        bold: true),
                    _ReceiptRow(label: 'Payment Method', value: 'Stripe'),
                    _ReceiptRow(
                        label: 'Date',
                        value: dateFmt.format(DateTime.now())),
                    _ReceiptRow(label: 'Account Status', value: 'Active ✓'),
                    const Divider(height: 20),
                    const Text('Transaction Reference',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SelectableText(
                      transactionRef,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF635BFF),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to Home',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  onPressed: () => _navigateToDashboard(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ReceiptRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: bold ? const Color(0xFF1A3A6B) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}