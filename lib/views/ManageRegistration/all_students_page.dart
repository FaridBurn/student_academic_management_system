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
        title: const Text('Delete Student', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will also delete registrations. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted'), backgroundColor: Colors.green)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
      );
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
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: idCtrl, 
                decoration: const InputDecoration(labelText: 'Student ID', border: OutlineInputBorder()), 
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl, 
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl, 
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl, 
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: progCtrl, 
                decoration: const InputDecoration(labelText: 'Programme', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: batchCtrl, 
                decoration: const InputDecoration(labelText: 'Batch', border: OutlineInputBorder())
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
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Student updated' : 'Student added'), 
                    backgroundColor: Colors.green
                  )
                );
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                );
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
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEdit(),
        backgroundColor: const Color(0xFF673AB7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Styled Search Area
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF3F51B5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            // Dynamic State List Display
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No students found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final s = _filtered[i];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.teal.shade700,
                                        radius: 24,
                                        child: Text(
                                          (s['stu_name'] != null && s['stu_name'].isNotEmpty)
                                              ? s['stu_name'][0].toString().toUpperCase()
                                              : '?',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s['stu_name'] ?? '', 
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              s['stu_email'] ?? '', 
                                              style: const TextStyle(fontSize: 12, color: Colors.black54)
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
                                                  child: Text(s['stu_programme'] ?? 'N/A', style: const TextStyle(fontSize: 11)),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
                                                  child: Text('Batch: ${s['stu_batch'] ?? 'N/A'}', style: const TextStyle(fontSize: 11)),
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
                                            onPressed: () => _showAddEdit(student: s),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
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
      ),
    );
  }
}