import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentReportPage extends StatefulWidget {
  const PaymentReportPage({super.key});

  @override
  State<PaymentReportPage> createState() => _PaymentReportPageState();
}

class _PaymentReportPageState extends State<PaymentReportPage> {
  final _db = Supabase.instance.client;
  bool _loading = true;

  int _totalStudents = 0;
  int _paidCount = 0;
  int _unpaidCount = 0;
  int _overdueCount = 0;
  double _totalExpected = 0;
  double _totalCollected = 0;
  List<Map<String, dynamic>> _recentPayments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fees = await _db
          .from('tuition_fees')
          .select('fee_id, total_fee, paid_amount, due_date, status');

      final payments = await _db
          .from('payments')
          .select('payment_id, student_id, amount, payment_method, payment_date, status')
          .eq('status', 'Success')
          .order('payment_date', ascending: false)
          .limit(10);

      // Enrich recent payments with names
      final List<Map<String, dynamic>> enriched = [];
      for (final p in payments as List) {
        final profile = await _db
            .from('profiles')
            .select('name')
            .eq('id', p['student_id'])
            .maybeSingle();
        enriched.add({...p, 'name': profile?['name'] ?? 'Unknown'});
      }

      final now = DateTime.now();
      int paid = 0, unpaid = 0, overdue = 0;
      double expected = 0, collected = 0;

      for (final f in fees as List) {
        expected += (f['total_fee'] as num).toDouble();
        if (f['status'] == 'Paid') {
          paid++;
          collected += (f['total_fee'] as num).toDouble();
        } else {
          unpaid++;
          final due = DateTime.parse(f['due_date'] as String);
          if (now.isAfter(due)) overdue++;
        }
      }

      setState(() {
        _totalStudents = (fees as List).length;
        _paidCount = paid;
        _unpaidCount = unpaid;
        _overdueCount = overdue;
        _totalExpected = expected;
        _totalCollected = collected;
        _recentPayments = enriched;
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

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final rate = _totalStudents == 0
        ? 0.0
        : (_paidCount / _totalStudents * 100);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Payment Report', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Collection rate card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Collection Rate',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('${rate.toStringAsFixed(1)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: rate / 100,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Collected: ${currency.format(_totalCollected)}',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Expected: ${currency.format(_totalExpected)}',
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _statCard('Total Records', '$_totalStudents',
                          Icons.people, Colors.blue),
                      _statCard('Paid', '$_paidCount',
                          Icons.check_circle, Colors.green),
                      _statCard('Unpaid', '$_unpaidCount',
                          Icons.pending, Colors.orange),
                      _statCard('Overdue', '$_overdueCount',
                          Icons.warning, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Recent payments
                  const Text('Recent Successful Payments',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_recentPayments.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No payments yet.',
                          style: TextStyle(color: Colors.grey)),
                    ))
                  else
                    ..._recentPayments.map((p) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade50,
                              child: Icon(Icons.receipt_long,
                                  color: Colors.green.shade700),
                            ),
                            title: Text(p['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              p['payment_date'] != null
                                  ? dateFmt.format(DateTime.parse(
                                      p['payment_date'] as String))
                                  : '-',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              currency.format(
                                  (p['amount'] as num).toDouble()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}