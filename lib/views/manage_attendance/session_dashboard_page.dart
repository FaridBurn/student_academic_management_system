import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/attendance_service.dart';
import 'create_session_page.dart';
import 'real_time_attendance_page.dart';
import 'attendance_report_page.dart';

class SessionDashboardPage extends StatefulWidget {
  const SessionDashboardPage({super.key});

  @override
  State<SessionDashboardPage> createState() => _SessionDashboardPageState();
}

class _SessionDashboardPageState extends State<SessionDashboardPage> {
  static const _green = Color(0xFF2E7D32);

  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  late String _lecturerId;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _lecturerId = Supabase.instance.client.auth.currentUser!.id;
    _load();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AttendanceService.getLecturerSessions(_lecturerId);
      if (!mounted) return;
      setState(() {
        _sessions = data;
        _loading = false;
      });
      _scheduleExpiryRefresh(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Sets a one-shot timer that fires the moment the soonest active session
  /// reaches its end time, triggering a reload to reflect the auto-close.
  void _scheduleExpiryRefresh(List<Map<String, dynamic>> sessions) {
    _expiryTimer?.cancel();
    final expiry = AttendanceService.nextSessionExpiry(sessions);
    if (expiry == null) return;
    final delay = expiry.difference(DateTime.now());
    if (delay.isNegative) return;
    _expiryTimer = Timer(delay, _load);
  }

  Future<void> _toggleActive(Map<String, dynamic> session) async {
    final isActive = session['is_active'] as bool;
    try {
      await AttendanceService.toggleSession(
          session['session_id'] as int, !isActive);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Class Sessions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Session'),
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateSessionPage(lecturerId: _lecturerId)));
          _load();
        },
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _sessions.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _sessions.length,
                    itemBuilder: (ctx, i) => _buildCard(_sessions[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> s) {
    final isActive = s['is_active'] as bool;
    final dateFmt = DateFormat('EEE, dd MMM yyyy');
    final date = DateTime.tryParse(s['session_date'] as String? ?? '') ??
        DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      isActive ? Colors.green.shade50 : Colors.grey.shade100,
                  child: Icon(Icons.class_,
                      color: isActive ? _green : Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['subject_code'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(dateFmt.format(date),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                _statusBadge(isActive),
              ],
            ),
            const SizedBox(height: 10),

            // Time row
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_fmtTime(s['start_time'])} – ${_fmtTime(s['end_time'])}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),

            // Code (only when active)
            if (isActive) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.key, size: 16, color: _green),
                    const SizedBox(width: 8),
                    const Text('Code:',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      s['attendance_code'] as String,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _green,
                        letterSpacing: 4,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: BorderSide(color: _green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('Attendance'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              RealTimeAttendancePage(session: s)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0288D1),
                      side:
                          const BorderSide(color: Color(0xFF0288D1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.bar_chart, size: 16),
                    label: const Text('Report'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AttendanceReportPage(session: s)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: isActive ? 'Close session' : 'Reopen session',
                  icon: Icon(
                    isActive ? Icons.lock_open : Icons.lock,
                    color: isActive ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () => _toggleActive(s),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isActive ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Text(
        isActive ? 'Active' : 'Closed',
        style: TextStyle(
          color: isActive ? _green : Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _fmtTime(dynamic t) {
    if (t == null) return '--:--';
    final parts = t.toString().split(':');
    if (parts.length < 2) return t.toString();
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${hour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $suffix';
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No sessions yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Tap + to create your first session.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
