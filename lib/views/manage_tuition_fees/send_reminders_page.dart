import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SendRemindersPage extends StatefulWidget {
  const SendRemindersPage({super.key});

  @override
  State<SendRemindersPage> createState() => _SendRemindersPageState();
}

class _SendRemindersPageState extends State<SendRemindersPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _unpaidStudents = [];
  bool _loading = true;
  final Set<int> _reminded = {};

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
          .select('fee_id, student_id, semester, academic_year, total_fee, due_date')
          .eq('status', 'Unpaid')
          .order('due_date', ascending: true);

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
          'phone': profile?['phone'] ?? '-',
        });
      }
      setState(() {
        _unpaidStudents = result;
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

  void _markReminded(int feeId) {
    setState(() => _reminded.add(feeId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder marked as sent.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: const Text('Send Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : _unpaidStudents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('All students have paid!',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            '${_unpaidStudents.length} student(s) have unpaid fees',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _unpaidStudents.length,
                          itemBuilder: (context, i) {
                            final s = _unpaidStudents[i];
                            final feeId = s['fee_id'] as int;
                            final dueDate = DateTime.parse(s['due_date'] as String);
                            final isOverdue = DateTime.now().isAfter(dueDate);
                            final alreadyReminded = _reminded.contains(feeId);

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
                                          backgroundColor: isOverdue
                                              ? Colors.red.shade50
                                              : Colors.orange.shade50,
                                          child: Icon(Icons.person,
                                              color: isOverdue
                                                  ? Colors.red
                                                  : Colors.orange),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(s['name'] as String,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15)),
                                              Text(s['email'] as String,
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        if (isOverdue)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: Colors.red.shade300),
                                            ),
                                            child: const Text('Overdue',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _infoChip(
                                            Icons.school,
                                            s['semester'] as String,
                                            Colors.blue),
                                        const SizedBox(width: 6),
                                        _infoChip(
                                            Icons.calendar_today,
                                            'Due: ${dateFmt.format(dueDate)}',
                                            isOverdue
                                                ? Colors.red
                                                : Colors.grey),
                                        const SizedBox(width: 6),
                                        _infoChip(
                                            Icons.payments,
                                            currency.format(
                                                (s['total_fee'] as num)
                                                    .toDouble()),
                                            Colors.green.shade700),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: alreadyReminded
                                              ? Colors.grey
                                              : const Color(0xFFE65100),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        icon: Icon(alreadyReminded
                                            ? Icons.check
                                            : Icons.notifications_active),
                                        label: Text(alreadyReminded
                                            ? 'Reminder Sent'
                                            : 'Mark as Reminded'),
                                        onPressed: alreadyReminded
                                            ? null
                                            : () => _markReminded(feeId),
                                      ),
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

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
