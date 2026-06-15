import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/attendance_service.dart';

class RealTimeAttendancePage extends StatefulWidget {
  final Map<String, dynamic> session;
  const RealTimeAttendancePage({super.key, required this.session});

  @override
  State<RealTimeAttendancePage> createState() => _RealTimeAttendancePageState();
}

class _RealTimeAttendancePageState extends State<RealTimeAttendancePage> {
  static const _green = Color(0xFF2E7D32);

  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 5 seconds for real-time updates while session is active
    if (widget.session['is_active'] == true) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await AttendanceService.getSessionAttendance(
          widget.session['session_id'] as int);
      if (mounted) {
        setState(() {
          _records = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.session['is_active'] as bool;
    final subjectCode = widget.session['subject_code'] as String;
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: Text(subjectCode,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // Session info header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.class_, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(subjectCode,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.greenAccent.shade700
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive) ...[
                            const SizedBox(
                              width: 8,
                              height: 8,
                              child: _PulseDot(),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isActive ? 'Live' : 'Closed',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${widget.session['session_date'] ?? ''}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    Text(
                      '${_loading ? '...' : _records.length} checked in',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.key,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Code: ${widget.session['attendance_code']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Attendance list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _green))
                : _records.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No students checked in yet.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _records.length,
                        itemBuilder: (ctx, i) {
                          final r = _records[i];
                          final checkIn = r['check_in_time'] != null
                              ? timeFmt.format(DateTime.parse(
                                  r['check_in_time'] as String))
                              : '--';
                          final verified = r['is_verified'] as bool? ?? false;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade50,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                      color: _green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(r['name'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(r['email'] as String,
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(checkIn,
                                      style: TextStyle(
                                          color: _green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        verified
                                            ? Icons.location_on
                                            : Icons.location_off,
                                        size: 12,
                                        color: verified
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        verified ? 'GPS ✓' : 'Web',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: verified
                                                ? Colors.green
                                                : Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
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

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}
