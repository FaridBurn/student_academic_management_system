import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/fee_controller.dart';
import 'payment_detail_page.dart';
import 'block_notification_page.dart';
import 'payment_history_page.dart';

class TuitionFeeDashboardPage extends StatefulWidget {
  final String studentUid;
  final String studentName;

  const TuitionFeeDashboardPage({
    super.key,
    required this.studentUid,
    required this.studentName,
  });

  @override
  State<TuitionFeeDashboardPage> createState() =>
      _TuitionFeeDashboardPageState();
}

class _TuitionFeeDashboardPageState extends State<TuitionFeeDashboardPage> {
  static const _red = Color(0xFFD32F2F);
  static const _bgColor = Color(0xFFFFEBEE);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeeDetails());
  }

  Future<void> _loadFeeDetails() async {
    final controller = context.read<FeeController>();
    await controller.requestFeeDetails(widget.studentUid);

    if (!context.mounted) return;

    final isBlocked = await controller.checkOverdueAndBlock(widget.studentUid);
    if (!context.mounted) return;
    if (isBlocked) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BlockNotificationPage(
            studentUid: widget.studentUid,
            studentName: widget.studentName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Tuition Fees'),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Payment History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PaymentHistoryPage(studentUid: widget.studentUid),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeeDetails,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<FeeController>(
        builder: (context, controller, _) {
          if (controller.feeState == FeeState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.feeState == FeeState.error) {
            return _buildError(controller.errorMessage ?? 'Unknown error');
          }

          if (controller.currentFee == null) {
            return _buildEmpty();
          }

          final fee = controller.currentFee!;
          final isPaid = fee.isPaid();
          final isOverdue = fee.isOverdue();
          final currencyFmt =
              NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
          final dateFmt = DateFormat('dd MMM yyyy');

          return RefreshIndicator(
            onRefresh: _loadFeeDetails,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Welcome header ───────────────────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.school,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.studentName.split(' ').first}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          const Text(
                            'Tuition Fee Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Fee card (matches co-curriculum card style) ──
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: _red.withValues(alpha: 0.15),
                          child: const Icon(
                              Icons.account_balance_wallet, color: _red),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tuition Fee',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _chip(fee.semester, Colors.blue),
                                  _chip(fee.academicYear, Colors.indigo),
                                  _chip(
                                    fee.status,
                                    isPaid
                                        ? Colors.green
                                        : (isOverdue
                                            ? Colors.red
                                            : Colors.orange),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.payments_outlined,
                                      size: 15, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    currencyFmt.format(fee.totalFee),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid
                                          ? Colors.green.shade700
                                          : _red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: isOverdue && !isPaid
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due: ${dateFmt.format(fee.dueDate)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isOverdue && !isPaid
                                          ? Colors.red
                                          : Colors.grey,
                                      fontWeight: isOverdue && !isPaid
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isPaid
                              ? Icons.check_circle
                              : Icons.pending_actions,
                          color: isPaid
                              ? Colors.green
                              : (isOverdue ? Colors.red : Colors.orange),
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Overdue warning ──────────────────────────────
                if (isOverdue && !isPaid)
                  Card(
                    color: Colors.red.shade50,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your payment is overdue. Academic access may be blocked.',
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── Pay / Paid button ────────────────────────────
                if (!isPaid)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.credit_card),
                      label: const Text(
                        'Pay Now',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentDetailPage(
                              studentUid: widget.studentUid),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade700, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Payment Completed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // ── History button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View Payment History'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PaymentHistoryPage(studentUid: widget.studentUid),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No fee record found.',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: _loadFeeDetails,
            child:
                const Text('Refresh', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _red),
              onPressed: _loadFeeDetails,
              child:
                  const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}