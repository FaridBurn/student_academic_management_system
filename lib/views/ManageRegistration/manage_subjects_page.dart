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
        title: const Text('Delete Subject', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will also delete registrations for this subject. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Cancel', style: TextStyle(color: Colors.grey))
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
      await Supabase.instance.client.from('subjects').delete().eq('subjectid', id);
      _fetch();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subject deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
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
        title: Text(
          isEdit ? 'Edit Subject' : 'Add Subject', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: idCtrl, 
                enabled: !isEdit,
                decoration: const InputDecoration(labelText: 'Subject ID', border: OutlineInputBorder()), 
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl, 
                decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl, 
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: creditCtrl, 
                decoration: const InputDecoration(labelText: 'Credit Hours', border: OutlineInputBorder()), 
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 12),
              TextField(
                controller: semCtrl, 
                decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder())
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
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Subject updated' : 'Subject added'), 
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  )
                );
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'), 
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  )
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
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF673AB7)),
                    ),
                    SizedBox(height: 16),
                    Text('Loading subject lists...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : _subjects.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No subjects found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                    itemCount: _subjects.length,
                    itemBuilder: (_, i) {
                      final s = _subjects[i];
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
                                    (s['sub_code'] != null && s['sub_code'].isNotEmpty)
                                        ? s['sub_code'][0].toString().toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${s['sub_code'] ?? ''} - ${s['sub_name'] ?? ''}', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
                                            child: Text('${s['credit_hours'] ?? 0} Credits', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
                                            child: Text(s['sub_semester'] ?? 'N/A', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
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
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _delete(s['subjectid']),
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
    );
  }
}