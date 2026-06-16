import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AllStudentsPage extends StatefulWidget {
  const AllStudentsPage({super.key});

  @override
  State<AllStudentsPage> createState() => _AllStudentsPageState();
}

class _AllStudentsPageState extends State<AllStudentsPage> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_filter);
  }

  Future<void> _fetch() async {
    try {
      final res = await Supabase.instance.client.from('students').select();
      setState(() {
        _students = List<Map<String, dynamic>>.from(res);
        _filtered = _students;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _students.where((s) =>
          s['stu_name'].toLowerCase().contains(q) ||
          s['stu_email'].toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Student'),
        content: const Text('This will also delete registrations. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('students').delete().eq('studentid', id);
      _fetch();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddEdit({Map<String, dynamic>? student}) {
    final isEdit = student != null;
    final idCtrl = TextEditingController(text: student?['studentid']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: student?['stu_name'] ?? '');
    final emailCtrl = TextEditingController(text: student?['stu_email'] ?? '');
    final passCtrl = TextEditingController(text: student?['stu_password'] ?? '');
    final progCtrl = TextEditingController(text: student?['stu_programme'] ?? '');
    final batchCtrl = TextEditingController(text: student?['stu_batch'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Edit Student' : 'Add Student', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Student ID'), keyboardType: TextInputType.number),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password')),
              TextField(controller: progCtrl, decoration: const InputDecoration(labelText: 'Programme')),
              TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'studentid': int.parse(idCtrl.text),
                'stu_name': nameCtrl.text,
                'stu_email': emailCtrl.text,
                'stu_password': passCtrl.text,
                'stu_programme': progCtrl.text,
                'stu_batch': batchCtrl.text,
              };
              try {
                if (isEdit) {
                  await Supabase.instance.client.from('students').update(data).eq('studentid', data['studentid']!);
                } else {
                  await Supabase.instance.client.from('students').insert(data);
                }
                Navigator.pop(ctx);
                _fetch();
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(isEdit ? 'Student updated' : 'Student added'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No students found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final s = _filtered[i];
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
                                  colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.teal.shade100,
                                      radius: 28,
                                      child: Text(s['stu_name'][0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s['stu_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text(s['stu_email'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Chip(label: Text(s['stu_programme'] ?? 'N/A'), backgroundColor: Colors.teal.shade50),
                                              const SizedBox(width: 8),
                                              Chip(label: Text('Batch: ${s['stu_batch'] ?? 'N/A'}'), backgroundColor: Colors.teal.shade50),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showAddEdit(student: s),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _delete(s['studentid']),
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
          ),
        ],
      ),
    );
  }
}