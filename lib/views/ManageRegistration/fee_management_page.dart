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
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: studentIdCtrl, 
                decoration: const InputDecoration(labelText: 'Student Profile ID (UUID)', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: semesterCtrl, 
                decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearCtrl, 
                decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalCtrl, 
                decoration: const InputDecoration(labelText: 'Total Fee', border: OutlineInputBorder()), 
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dueCtrl, 
                decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)', border: OutlineInputBorder())
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Fee record added successfully'), 
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  )
                );
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'), 
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  )
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invoice marked as paid'), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFee,
        backgroundColor: const Color(0xFF673AB7),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Fee Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF673AB7))),
                    SizedBox(height: 16),
                    Text('Loading tuition logs...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : _fees.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No ledger transactions recorded', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
                    itemCount: _fees.length,
                    itemBuilder: (_, i) {
                      final f = _fees[i];
                      final profile = f['profiles'] as Map<String, dynamic>?;
                      final isPaid = f['status'] == 'Paid';
                      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isPaid 
                                  ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)] 
                                  : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
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
                                      backgroundColor: isPaid ? Colors.teal.shade700 : const Color(0xFF1976D2),
                                      radius: 22,
                                      child: Text(
                                        profile?['name'] != null ? profile!['name'][0].toString().toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile?['name'] ?? f['student_id'].toString(), 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            profile?['email'] ?? 'No linked profile account', 
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPaid ? Colors.green.shade200 : Colors.orange.shade200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        f['status'].toString().toUpperCase(),
                                        style: TextStyle(
                                          color: isPaid ? Colors.green.shade900 : Colors.orange.shade900, 
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Semester', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                          const SizedBox(height: 2),
                                          Text(f['semester'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Total Due', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                          const SizedBox(height: 2),
                                          Text('RM ${f['total_fee']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 13)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Due Date', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                          const SizedBox(height: 2),
                                          Text(f['due_date'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isPaid) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _markPaid(f['fee_id']),
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      label: const Text('Mark as Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32), 
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}