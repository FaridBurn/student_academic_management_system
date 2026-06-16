import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpenRegistrationPage extends StatefulWidget {
  const OpenRegistrationPage({super.key});

  @override
  State<OpenRegistrationPage> createState() => _OpenRegistrationPageState();
}

class _OpenRegistrationPageState extends State<OpenRegistrationPage> {
  List<Map<String, dynamic>> _registrations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final registrations = await Supabase.instance.client
          .from('registrations')
          .select()
          .eq('status', 'Pending');

      final List<Map<String, dynamic>> enriched = [];
      for (var reg in registrations) {
        final student = await Supabase.instance.client
            .from('students')
            .select('stu_name, stu_email')
            .eq('studentid', reg['studentid'])
            .maybeSingle();

        final subject = await Supabase.instance.client
            .from('subjects')
            .select('sub_code, sub_name, credit_hours')
            .eq('subjectid', reg['subjectid'])
            .maybeSingle();

        enriched.add({
          ...reg,
          'students': student ?? {'stu_name': 'Unknown', 'stu_email': 'unknown'},
          'subjects': subject ?? {'sub_code': 'N/A', 'sub_name': 'N/A', 'credit_hours': 0},
        });
      }

      setState(() {
        _registrations = enriched;
        _loading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int regId, String status, {String? reason}) async {
    try {
      final update = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (reason != null && reason.isNotEmpty) update['reject_reason'] = reason;
      await Supabase.instance.client
          .from('registrations')
          .update(update)
          .eq('registrationid', regId);
      _fetch();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration $status'), backgroundColor: status == 'Approved' ? Colors.green : Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _rejectDialog(int regId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Registration', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(hintText: 'Reason (optional)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateStatus(regId, 'Rejected', reason: reasonCtrl.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Registration'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _registrations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No pending registrations', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _registrations.length,
                  itemBuilder: (ctx, i) {
        final reg = _registrations[i];
        final student = reg['students'] as Map<String, dynamic>;
        final subject = reg['subjects'] as Map<String, dynamic>;
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
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
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(student['stu_name'][0], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student['stu_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(student['stu_email'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Chip(
                        label: const Text('Pending'),
                        backgroundColor: Colors.orange.shade100,
                        labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.book, color: Colors.deepPurple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${subject['sub_code']} - ${subject['sub_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${reg['semester']} ${reg['academic_year']} | ${subject['credit_hours']} credits', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(reg['registrationid'], 'Approved'),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _rejectDialog(reg['registrationid']),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
            ),
    );
  }
}