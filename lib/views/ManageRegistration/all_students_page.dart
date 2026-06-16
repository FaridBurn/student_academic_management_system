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
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.from('students').select();
      setState(() {
        _students = List<Map<String, dynamic>>.from(res);
        _filtered = List.from(_students);
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _students.where((s) {
        final name = (s['stu_name'] ?? '').toString().toLowerCase();
        final email = (s['stu_email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Student'),
        content: const Text('This will also delete their registrations. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('students').delete().eq('studentid', id);
      _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
        title: Text(
          isEdit ? 'Edit Student' : 'Add Student',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  filled: isEdit,
                  fillColor: isEdit ? Colors.grey.shade100 : null,
                ),
                keyboardType: TextInputType.number,
                readOnly: isEdit,
              ),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 8),
              TextField(controller: progCtrl, decoration: const InputDecoration(labelText: 'Programme')),
              const SizedBox(height: 8),
              TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
            onPressed: () async {
              // Validate required fields
              if (!isEdit && idCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student ID is required'), backgroundColor: Colors.red),
                );
                return;
              }
              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and Email are required'), backgroundColor: Colors.red),
                );
                return;
              }
              final int? parsedId = int.tryParse(idCtrl.text.trim());
              if (!isEdit && parsedId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student ID must be a number'), backgroundColor: Colors.red),
                );
                return;
              }

              final data = <String, dynamic>{
                'stu_name': nameCtrl.text.trim(),
                'stu_email': emailCtrl.text.trim(),
                'stu_password': passCtrl.text,
                'stu_programme': progCtrl.text.trim(),
                'stu_batch': batchCtrl.text.trim(),
              };

              try {
                if (isEdit) {
                  await Supabase.instance.client
                      .from('students')
                      .update(data)
                      .eq('studentid', student['studentid']);
                } else {
                  data['studentid'] = parsedId;
                  await Supabase.instance.client.from('students').insert(data);
                }
                Navigator.pop(ctx);
                _fetch();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Student updated' : 'Student added'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Students'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEdit(),
        backgroundColor: const Color(0xFF6A1B9A),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Student', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 12),
                            const Text('Failed to load students', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
                          ],
                        ),
                      )
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
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final s = _filtered[i];
                                final name = (s['stu_name'] ?? 'Unknown').toString();
                                final email = (s['stu_email'] ?? '').toString();
                                final programme = (s['stu_programme'] ?? 'N/A').toString();
                                final batch = (s['stu_batch'] ?? 'N/A').toString();
                                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.teal.shade200,
                                                radius: 26,
                                                child: Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                    const SizedBox(height: 2),
                                                    Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                                    tooltip: 'Edit',
                                                    onPressed: () => _showAddEdit(student: s),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    tooltip: 'Delete',
                                                    onPressed: () => _delete(s['studentid']),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Chip(
                                                avatar: const Icon(Icons.school, size: 14, color: Colors.teal),
                                                label: Text(programme, style: const TextStyle(fontSize: 12)),
                                                backgroundColor: Colors.teal.shade50,
                                                padding: EdgeInsets.zero,
                                              ),
                                              Chip(
                                                avatar: const Icon(Icons.calendar_today, size: 14, color: Colors.teal),
                                                label: Text('Batch: $batch', style: const TextStyle(fontSize: 12)),
                                                backgroundColor: Colors.teal.shade50,
                                                padding: EdgeInsets.zero,
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
          ),
        ],
      ),
    );
  }
}
