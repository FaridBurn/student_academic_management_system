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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student report downloaded'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loadingStudents = false);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration report downloaded'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loadingRegistrations = false);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee report downloaded'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loadingFees = false);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject report downloaded'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loadingSubjects = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Generate Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Export data as CSV files', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildReportCard(
            icon: Icons.people,
            title: 'Student Report',
            subtitle: 'Export all students with ID, name, email, programme, batch',
            color: Colors.blue,
            onPressed: _generateStudentReport,
            loading: _loadingStudents,
          ),
          _buildReportCard(
            icon: Icons.assignment,
            title: 'Registration Report',
            subtitle: 'Export all registrations with status, semester, student and subject IDs',
            color: Colors.orange,
            onPressed: _generateRegistrationReport,
            loading: _loadingRegistrations,
          ),
          _buildReportCard(
            icon: Icons.attach_money,
            title: 'Fee Report',
            subtitle: 'Export tuition fee records with amount, due date, payment status',
            color: Colors.green,
            onPressed: _generateFeeReport,
            loading: _loadingFees,
          ),
          _buildReportCard(
            icon: Icons.book,
            title: 'Subject Report',
            subtitle: 'Export all subjects with code, name, credit hours, semester',
            color: Colors.purple,
            onPressed: _generateSubjectReport,
            loading: _loadingSubjects,
          ),
        ],
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
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: loading ? null : onPressed,
                icon: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                label: Text(loading ? 'Exporting...' : 'Export CSV'),
                style: ElevatedButton.styleFrom(backgroundColor: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}