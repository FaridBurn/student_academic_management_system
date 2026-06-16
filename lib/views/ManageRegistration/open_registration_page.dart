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

  Future<void> _updateStatus(int regId, String status) async {
    try {
      await Supabase.instance.client
          .from('registrations')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('registrationid', regId);
      _fetch();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'Approved' ? Icons.check_circle_outline : Icons.remove_circle_outline, 
                color: Colors.white
              ),
              const SizedBox(width: 12),
              Text('Registration $status successfully'),
            ],
          ),
          backgroundColor: status == 'Approved' ? Colors.greenAccent : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _rejectDialog(int regId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.gavel_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 12),
            Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provide a justification reason for declining this request:',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason (optional)', 
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              await _updateStatus(regId, 'Rejected');
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF673AB7)),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text('Fetching operations...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            : _registrations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8EAF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_turned_in_rounded, size: 64, color: Color(0xFF3F51B5)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'All Clear!',
                          style: TextStyle(fontSize: 20, color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'No pending registrations await evaluation.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _registrations.length,
                    itemBuilder: (ctx, i) {
                      final reg = _registrations[i];
                      final student = reg['students'] as Map<String, dynamic>;
                      final subject = reg['subjects'] as Map<String, dynamic>;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFE3F2FD), Color(0xFFE0F2F1)],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Profile header section
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF3F51B5),
                                        radius: 22,
                                        child: Text(
                                          (student['stu_name'] != null && student['stu_name'].isNotEmpty)
                                              ? student['stu_name'][0].toString().toUpperCase()
                                              : '?',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['stu_name'] ?? 'Unknown Student', 
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF263238))
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              student['stu_email'] ?? '', 
                                              style: const TextStyle(fontSize: 12, color: Colors.black54)
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'PENDING',
                                          style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Enrolled course display details
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white, width: 1),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(Icons.auto_stories, color: Color(0xFF00897B), size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${subject['sub_code'] ?? 'N/A'} — ${subject['sub_name'] ?? 'N/A'}', 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Term: ${reg['semester'] ?? ''} ${reg['academic_year'] ?? ''}   •   ${subject['credit_hours'] ?? 0} Credits', 
                                                style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Evaluation button container block
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _rejectDialog(reg['registrationid']),
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(color: Colors.redAccent, width: 1),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _updateStatus(reg['registrationid'], 'Approved'),
                                        icon: const Icon(Icons.check_rounded, size: 16),
                                        label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00897B),
                                          foregroundColor: Colors.white,
                                          elevation: 1,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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