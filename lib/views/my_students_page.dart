import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyStudentsPage extends StatefulWidget {
  final String lecturerEmail;
  const MyStudentsPage({super.key, required this.lecturerEmail});

  @override
  State<MyStudentsPage> createState() => _MyStudentsPageState();
}

class _MyStudentsPageState extends State<MyStudentsPage> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      // Get lecturer ID
      final lecturer = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('email', widget.lecturerEmail)
          .maybeSingle();
      if (lecturer == null) {
        setState(() => _loading = false);
        return;
      }
      final lecturerId = lecturer['id'];

      // Get subjects taught by this lecturer
      final subjects = await Supabase.instance.client
          .from('subjects')
          .select('subjectid')
          .eq('lecturer_id', lecturerId);
      final subjectIds = (subjects as List).map((s) => s['subjectid']).toList();
      if (subjectIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Get all approved registrations
      final allRegistrations = await Supabase.instance.client
          .from('registrations')
          .select('studentid, subjectid')
          .eq('status', 'Approved');
      
      // Filter to relevant subjects
      final relevantRegs = (allRegistrations as List)
          .where((reg) => subjectIds.contains(reg['subjectid']))
          .toList();
      
      final studentIds = relevantRegs.map((r) => r['studentid']).toSet().toList();
      if (studentIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Get all students
      final allStudents = await Supabase.instance.client
          .from('students')
          .select('stu_name, stu_email, stu_programme, studentid');
      
      final filteredStudents = (allStudents as List)
          .where((s) => studentIds.contains(s['studentid']))
          .toList();

      setState(() {
        _students = filteredStudents.map((s) => {
          'stu_name': s['stu_name'],
          'stu_email': s['stu_email'],
          'stu_programme': s['stu_programme'],
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Students')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students enrolled in your subjects yet.'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final s = _students[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(s['stu_name']),
                      subtitle: Text(s['stu_email']),
                      trailing: Chip(label: Text(s['stu_programme'])),
                    );
                  },
                ),
    );
  }
}