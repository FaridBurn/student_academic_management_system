import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../services/attendance_service.dart';

class AttendanceReportPage extends StatefulWidget {
  final Map<String, dynamic> session;
  const AttendanceReportPage({super.key, required this.session});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  static const _blue = Color(0xFF0288D1);

  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AttendanceService.getSessionAttendance(
          widget.session['session_id'] as int);
      setState(() {
        _records = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _buildReportText() {
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final date = DateTime.tryParse(
            widget.session['session_date'] as String? ?? '') ??
        DateTime.now();
    final buf = StringBuffer();
    buf.writeln('ATTENDANCE REPORT');
    buf.writeln('=================');
    buf.writeln('Subject : ${widget.session['subject_code']}');
    buf.writeln('Date    : ${dateFmt.format(date)}');
    buf.writeln(
        'Time    : ${widget.session['start_time']} – ${widget.session['end_time']}');
    buf.writeln('Total   : ${_records.length} student(s)');
    buf.writeln('-----------------');
    for (int i = 0; i < _records.length; i++) {
      final r = _records[i];
      final checkIn = r['check_in_time'] != null
          ? timeFmt.format(DateTime.parse(r['check_in_time'] as String))
          : '--';
      buf.writeln('${(i + 1).toString().padLeft(2)}. ${r['name']}  |  $checkIn');
    }
    buf.writeln('=================');
    buf.writeln('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}');
    return buf.toString();
  }

  void _copyReport() {
    Clipboard.setData(ClipboardData(text: _buildReportText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final date = DateTime.tryParse(
            widget.session['session_date'] as String? ?? '') ??
        DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text('Attendance Report',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy report',
              onPressed: _loading ? null : _copyReport),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _blue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Session summary card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.session['subject_code'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(dateFmt.format(date),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _summaryItem('Students\nPresent',
                              '${_records.length}', Icons.people),
                          _summaryItem(
                              'GPS\nVerified',
                              '${_records.where((r) => r['is_verified'] == true).length}',
                              Icons.location_on),
                          _summaryItem('Session\nStatus',
                              widget.session['is_active'] == true ? 'Active' : 'Closed',
                              Icons.info_outline),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Attendance List',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                if (_records.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No students checked in.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ..._records.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final checkIn = r['check_in_time'] != null
                        ? timeFmt.format(
                            DateTime.parse(r['check_in_time'] as String))
                        : '--';
                    final verified = r['is_verified'] as bool? ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: _blue,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(r['name'] as String,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(r['email'] as String,
                            style: const TextStyle(fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(checkIn,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _blue,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Icon(
                              verified
                                  ? Icons.verified
                                  : Icons.help_outline,
                              size: 14,
                              color: verified ? Colors.green : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: _blue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Report to Clipboard'),
                  onPressed: _copyReport,
                ),
              ],
            ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
