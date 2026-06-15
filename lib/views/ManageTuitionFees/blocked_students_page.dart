import 'package:flutter/material.dart';
import '../../services/supabase_fee_service.dart';

class BlockedStudentsPage extends StatefulWidget {
  const BlockedStudentsPage({super.key});

  @override
  State<BlockedStudentsPage> createState() => _BlockedStudentsPageState();
}

class _BlockedStudentsPageState extends State<BlockedStudentsPage> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseFeeService.getBlockedStudents();
      setState(() {
        _students = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _unblock(String studentId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unblock Student'),
        content: Text('Restore academic access for $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseFeeService.updateStudentBlockStatus(studentId, false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name has been unblocked.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to unblock: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        title: const Text('Blocked Students', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
          : _students.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('No blocked students.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            '${_students.length} student(s) blocked',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _students.length,
                          itemBuilder: (context, i) {
                            final s = _students[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.red.shade50,
                                      child: const Icon(Icons.person_off,
                                          color: Colors.red),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s['name'] as String,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15)),
                                          Text(s['email'] as String,
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                          if ((s['programme'] as String?) != null)
                                            Text(s['programme'] as String,
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.green),
                                      icon: const Icon(Icons.lock_open, size: 18),
                                      label: const Text('Unblock'),
                                      onPressed: () => _unblock(
                                          s['id'] as String, s['name'] as String),
                                    ),
                                  ],
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