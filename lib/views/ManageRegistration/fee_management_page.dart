import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeeManagementPage extends StatefulWidget {
  const FeeManagementPage({super.key});

  @override
  State<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends State<FeeManagementPage> {
  List<Map<String, dynamic>> _fees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await Supabase.instance.client
          .from('tuition_fees')
          .select('*, profiles:student_id (name, email)');
      setState(() {
        _fees = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _addFee() {
    final studentIdCtrl = TextEditingController();
    final semesterCtrl = TextEditingController(text: 'Semester 1');
    final yearCtrl = TextEditingController(text: '2025/2026');
    final totalCtrl = TextEditingController();
    final dueCtrl = TextEditingController(
      text: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Fee Record', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: studentIdCtrl, decoration: const InputDecoration(labelText: 'Student Profile ID (UUID)')),
              TextField(controller: semesterCtrl, decoration: const InputDecoration(labelText: 'Semester')),
              TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Academic Year')),
              TextField(controller: totalCtrl, decoration: const InputDecoration(labelText: 'Total Fee'), keyboardType: TextInputType.number),
              TextField(controller: dueCtrl, decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {
                  'student_id': studentIdCtrl.text,
                  'semester': semesterCtrl.text,
                  'academic_year': yearCtrl.text,
                  'total_fee': double.parse(totalCtrl.text),
                  'due_date': dueCtrl.text,
                  'status': 'Unpaid',
                };
                await Supabase.instance.client.from('tuition_fees').insert(data);
                Navigator.pop(ctx);
                _fetch();
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Fee record added'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaid(int feeId) async {
    try {
      await Supabase.instance.client
          .from('tuition_fees')
          .update({'status': 'Paid'})
          .eq('fee_id', feeId);
      _fetch();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as paid'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Fee Record',
            onPressed: _addFee,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _fees.length,
                    itemBuilder: (_, i) {
                      final f = _fees[i];
                      final profile = f['profiles'] as Map<String, dynamic>?;
                      final isPaid = f['status'] == 'Paid';
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isPaid ? [Color(0xFFE8F5E9), Color(0xFFC8E6C9)] : [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                                      child: Text(profile?['name']?[0] ?? '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(profile?['name'] ?? f['student_id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(profile?['email'] ?? 'No email', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(f['status']),
                                      backgroundColor: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                                      labelStyle: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Semester', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text(f['semester'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Total Fee', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text('RM${f['total_fee']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Due Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text(f['due_date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (!isPaid)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _markPaid(f['fee_id']),
                                      icon: const Icon(Icons.payment),
                                      label: const Text('Mark as Paid'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}