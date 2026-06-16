import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MySubjectsPage extends StatefulWidget {
  final String lecturerEmail;
  const MySubjectsPage({super.key, required this.lecturerEmail});

  @override
  State<MySubjectsPage> createState() => _MySubjectsPageState();
}

class _MySubjectsPageState extends State<MySubjectsPage> {
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      // First get lecturer ID from profiles table
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

      // Then fetch subjects where lecturer_id matches
      final response = await Supabase.instance.client
          .from('subjects')
          .select('sub_code, sub_name, credit_hours, sub_semester')
          .eq('lecturer_id', lecturerId);
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Subjects')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const Center(child: Text('No subjects assigned yet.'))
              : ListView.builder(
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final s = _subjects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text('${s['sub_code']} - ${s['sub_name']}'),
                        subtitle: Text('${s['credit_hours']} credits · ${s['sub_semester']}'),
                      ),
                    );
                  },
                ),
    );
  }
}