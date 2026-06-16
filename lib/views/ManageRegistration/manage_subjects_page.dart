import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageSubjectsPage extends StatefulWidget {
  const ManageSubjectsPage({super.key});

  @override
  State<ManageSubjectsPage> createState() => _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends State<ManageSubjectsPage> {
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await Supabase.instance.client.from('subjects').select();
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Subject'),
        content: const Text('This will also delete registrations for this subject. Continue?'),
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
      await Supabase.instance.client.from('subjects').delete().eq('subjectid', id);
      _fetch();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject deleted'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddEdit({Map<String, dynamic>? subject}) {
    final isEdit = subject != null;
    final idCtrl = TextEditingController(text: subject?['subjectid']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: subject?['sub_code'] ?? '');
    final nameCtrl = TextEditingController(text: subject?['sub_name'] ?? '');
    final creditCtrl = TextEditingController(text: subject?['credit_hours']?.toString() ?? '');
    final semCtrl = TextEditingController(text: subject?['sub_semester'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Edit Subject' : 'Add Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Subject ID'), keyboardType: TextInputType.number),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: creditCtrl, decoration: const InputDecoration(labelText: 'Credit Hours'), keyboardType: TextInputType.number),
              TextField(controller: semCtrl, decoration: const InputDecoration(labelText: 'Semester')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'subjectid': int.parse(idCtrl.text),
                'sub_code': codeCtrl.text,
                'sub_name': nameCtrl.text,
                'credit_hours': int.parse(creditCtrl.text),
                'sub_semester': semCtrl.text,
              };
              try {
                if (isEdit) {
                  await Supabase.instance.client.from('subjects').update(data).eq('subjectid', data['subjectid']!);
                } else {
                  await Supabase.instance.client.from('subjects').insert(data);
                }
                Navigator.pop(ctx);
                _fetch();
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(isEdit ? 'Subject updated' : 'Subject added'), backgroundColor: Colors.green));
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_subjects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No subjects found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return Material(
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _subjects.length,
        itemBuilder: (_, i) {
          final s = _subjects[i];
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
                  colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
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
                          child: Text(s['sub_code'][0], style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s['sub_code']} - ${s['sub_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Chip(
                                    label: Text('${s['credit_hours']} credits'),
                                    backgroundColor: Colors.deepPurple.shade50,
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(s['sub_semester']),
                                    backgroundColor: Colors.deepPurple.shade50,
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEdit(subject: s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _delete(s['subjectid']),
                            ),
                          ],
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