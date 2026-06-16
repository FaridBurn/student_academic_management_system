import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../utils/file_download.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _loadingStudents = false;
  bool _loadingRegistrations = false;
  bool _loadingFees = false;
  bool _loadingSubjects = false;

  Future<void> _exportCSV(String title, List<Map<String, dynamic>> data, List<String> headers, List<String> keys) async {
    final rows = [headers.join(',')];
    for (var row in data) {
      final line = keys.map((k) => row[k]?.toString() ?? '').join(',');
      rows.add(line);
    }
    final csv = rows.join('\n');
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await downloadBytes('${title}_${DateTime.now().toIso8601String()}.csv', bytes);
  }

  Future<void> _generateStudentReport() async {
    setState(() => _loadingStudents = true);
    try {
      final data = await Supabase.instance.client
          .from('students')
          .select('studentid, stu_name, stu_email, stu_programme, stu_batch');
      await _exportCSV('students', List<Map<String, dynamic>>.from(data),
          ['Student ID', 'Name', 'Email', 'Programme', 'Batch'],
          ['studentid', 'stu_name', 'stu_email', 'stu_programme', 'stu_batch']);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Student report downloaded successfully'), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error student database export: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _generateRegistrationReport() async {
    setState(() => _loadingRegistrations = true);
    try {
      final data = await Supabase.instance.client
          .from('registrations')
          .select('registrationid, studentid, subjectid, semester, academic_year, status, registered_at');
      await _exportCSV('registrations', List<Map<String, dynamic>>.from(data),
          ['Reg ID', 'Student ID', 'Subject ID', 'Semester', 'Academic Year', 'Status', 'Registered At'],
          ['registrationid', 'studentid', 'subjectid', 'semester', 'academic_year', 'status', 'registered_at']);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration report downloaded successfully'), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error registration data export: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingRegistrations = false);
    }
  }

  Future<void> _generateFeeReport() async {
    setState(() => _loadingFees = true);
    try {
      final data = await Supabase.instance.client
          .from('tuition_fees')
          .select('fee_id, student_id, semester, academic_year, total_fee, due_date, status, paid_amount');
      await _exportCSV('fees', List<Map<String, dynamic>>.from(data),
          ['Fee ID', 'Student ID', 'Semester', 'Academic Year', 'Total Fee', 'Due Date', 'Status', 'Paid Amount'],
          ['fee_id', 'student_id', 'semester', 'academic_year', 'total_fee', 'due_date', 'status', 'paid_amount']);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Financial ledger report downloaded successfully'), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fee history export: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingFees = false);
    }
  }

  Future<void> _generateSubjectReport() async {
    setState(() => _loadingSubjects = true);
    try {
      final data = await Supabase.instance.client
          .from('subjects')
          .select('subjectid, sub_code, sub_name, credit_hours, sub_semester');
      await _exportCSV('subjects', List<Map<String, dynamic>>.from(data),
          ['Subject ID', 'Code', 'Name', 'Credit Hours', 'Semester'],
          ['subjectid', 'sub_code', 'sub_name', 'credit_hours', 'sub_semester']);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Curriculum subject report downloaded'), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error course listing export: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Generate Reports', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              const Text('Export live structural data tables as portable CSV documents', style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 24),
              _buildReportCard(
                icon: Icons.people_outline,
                title: 'Student Report',
                subtitle: 'Export student master files containing active profile parameters, email values, and registered batches.',
                color: const Color(0xFF1976D2),
                onPressed: _generateStudentReport,
                loading: _loadingStudents,
              ),
              _buildReportCard(
                icon: Icons.assignment_outlined,
                title: 'Registration Report',
                subtitle: 'Download course confirmation structures containing current validation codes, dates, and subject profiles.',
                color: const Color(0xFFE65100),
                onPressed: _generateRegistrationReport,
                loading: _loadingRegistrations,
              ),
              _buildReportCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Fee Report',
                subtitle: 'Generate standard financial reports reflecting total outstanding bills, complete parameters, and clear invoice tracking.',
                color: const Color(0xFF2E7D32),
                onPressed: _generateFeeReport,
                loading: _loadingFees,
              ),
              _buildReportCard(
                icon: Icons.book_outlined,
                title: 'Subject Report',
                subtitle: 'Compile curriculum configuration indexes containing full course catalog details and expected core values.',
                color: const Color(0xFF673AB7),
                onPressed: _generateSubjectReport,
                loading: _loadingSubjects,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
    required bool loading,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 26, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black, height: 1.4)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onPressed,
                  icon: loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(loading ? 'Generating Document...' : 'Export CSV File', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: color.withOpacity(0.4),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}