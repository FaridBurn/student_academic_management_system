import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_fee_service.dart';

class VerifyPaymentsPage extends StatefulWidget {
  const VerifyPaymentsPage({super.key});

  @override
  State<VerifyPaymentsPage> createState() => _VerifyPaymentsPageState();
}

class _VerifyPaymentsPageState extends State<VerifyPaymentsPage> {
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseFeeService.getAllPaymentsWithProfiles();
      setState(() {
        _payments = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _payments;
    return _payments.where((p) => p['status'] == _filter).toList();
  }

  Future<void> _updateStatus(
      int paymentId, int feeId, String newStatus, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mark as $newStatus'),
        content: Text('Set payment by $name to "$newStatus"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: newStatus == 'Success'
                    ? Colors.green
                    : Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseFeeService.updatePaymentAndFeeStatus(
        paymentId: paymentId,
        feeId: feeId,
        newPaymentStatus: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment updated to $newStatus.'),
            backgroundColor: newStatus == 'Success' ? Colors.green : Colors.red,
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        title: const Text('Verify Payments',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Success', 'Failed', 'Cancelled'].map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: const Color(0xFF00838F),
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00838F)))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No payments found.',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final p = _filtered[i];
                            final status = p['status'] as String;
                            final paymentId = p['payment_id'] as int;
                            final feeId = p['fee_id'] as int;

                            Color statusColor;
                            if (status == 'Success') {
                              statusColor = Colors.green;
                            } else if (status == 'Failed') {
                              statusColor = Colors.red;
                            } else {
                              statusColor = Colors.orange;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: statusColor
                                              .withValues(alpha: 0.12),
                                          child: Icon(Icons.receipt_long,
                                              color: statusColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(p['name'] as String,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                              Text(p['email'] as String,
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: statusColor
                                                    .withValues(alpha: 0.4)),
                                          ),
                                          child: Text(status,
                                              style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.payments_outlined,
                                            size: 13, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                            currency.format(
                                                (p['amount'] as num).toDouble()),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 12),
                                        Icon(Icons.calendar_today_outlined,
                                            size: 13, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          p['payment_date'] != null
                                              ? dateFmt.format(DateTime.parse(
                                                  p['payment_date'] as String))
                                              : '-',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    if ((p['transaction_ref'] as String?) !=
                                        null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ref: ${p['transaction_ref']}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF635BFF),
                                            fontFamily: 'monospace'),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        if (status != 'Success')
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.green,
                                                side: const BorderSide(
                                                    color: Colors.green),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              icon: const Icon(Icons.check,
                                                  size: 16),
                                              label: const Text('Approve'),
                                              onPressed: () => _updateStatus(
                                                  paymentId,
                                                  feeId,
                                                  'Success',
                                                  p['name'] as String),
                                            ),
                                          ),
                                        if (status != 'Success' &&
                                            status != 'Failed')
                                          const SizedBox(width: 8),
                                        if (status != 'Failed')
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(
                                                    color: Colors.red),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              icon: const Icon(Icons.close,
                                                  size: 16),
                                              label: const Text('Reject'),
                                              onPressed: () => _updateStatus(
                                                  paymentId,
                                                  feeId,
                                                  'Failed',
                                                  p['name'] as String),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}