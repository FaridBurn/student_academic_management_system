import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/registration_controller.dart';

class TimetableViewPage extends StatefulWidget {
  const TimetableViewPage({super.key});

  @override
  State<TimetableViewPage> createState() => _TimetableViewPageState();
}

class _TimetableViewPageState extends State<TimetableViewPage> {
  List<Map<String, dynamic>> _timetable = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    final controller = context.read<RegistrationController>();
    final data = await controller.fetchTimetable('Sem1', '2025/2026');
    setState(() {
      _timetable = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimetable,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timetable.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No approved registrations yet'),
                      SizedBox(height: 8),
                      Text('Your timetable will appear after registration is approved'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _timetable.length,
                  itemBuilder: (context, index) {
                    final reg = _timetable[index];
                    final subjectData = reg['subjects'] as Map<String, dynamic>?;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            subjectData?['credit_hours']?.toString() ?? '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          '${subjectData?['sub_code'] ?? 'N/A'} - ${subjectData?['sub_name'] ?? 'Unknown'}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${reg['status']}'),
                            const Text('Schedule: Monday, 10:00 AM - 12:00 PM'),
                          ],
                        ),
                        trailing: const Chip(
                          label: Text('Approved'),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}