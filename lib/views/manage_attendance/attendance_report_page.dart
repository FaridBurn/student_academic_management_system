import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../services/attendance_service.dart';
import '../../../utils/file_download.dart';

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
  bool _exporting = false;

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

  // Exporting to PDF and Excel

  Future<void> _downloadPdf() async {
    setState(() => _exporting = true);
    try {
      final doc = _buildPdfDocument();
      final subjectCode =
          (widget.session['subject_code'] as String).replaceAll(' ', '_');
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'attendance_$subjectCode.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Document _buildPdfDocument() {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final date =
        DateTime.tryParse(widget.session['session_date'] as String? ?? '') ??
            DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text(
            'ATTENDANCE REPORT',
            style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfRow('Subject', widget.session['subject_code'] as String),
                _pdfRow('Date', dateFmt.format(date)),
                _pdfRow(
                  'Time',
                  '${widget.session['start_time']} – ${widget.session['end_time']}',
                ),
                _pdfRow('Total', '${_records.length} student(s)'),
                _pdfRow(
                  'Status',
                  widget.session['is_active'] == true ? 'Active' : 'Closed',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['No.', 'Name', 'Email', 'Check-in Time', 'GPS'],
            data: _records.asMap().entries.map((e) {
              final r = e.value;
              final checkIn = r['check_in_time'] != null
                  ? timeFmt
                      .format(DateTime.parse(r['check_in_time'] as String))
                  : '--';
              return [
                '${e.key + 1}',
                r['name'] as String,
                r['email'] as String,
                checkIn,
                r['is_verified'] == true ? 'Yes' : 'No',
              ];
            }).toList(),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellAlignments: {
              0: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            border: pw.TableBorder.all(color: PdfColors.blueGrey200),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey50),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text('$label',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                    fontSize: 11, color: PdfColors.blueGrey700)),
          ),
          pw.Text(': $value', style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ── Excel ────────────────────────────────────────────────────────────────

  Future<void> _downloadExcel() async {
    setState(() => _exporting = true);
    try {
      final ex = Excel.createExcel();
      // Remove the default empty sheet
      ex.delete('Sheet1');
      final sheet = ex['Attendance'];

      // Info rows
      final dateFmt = DateFormat('dd MMM yyyy');
      final timeFmt = DateFormat('hh:mm a');
      final date =
          DateTime.tryParse(widget.session['session_date'] as String? ?? '') ??
              DateTime.now();

      sheet.appendRow([
        TextCellValue('Subject'),
        TextCellValue(widget.session['subject_code'] as String),
      ]);
      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue(dateFmt.format(date)),
      ]);
      sheet.appendRow([
        TextCellValue('Time'),
        TextCellValue(
            '${widget.session['start_time']} – ${widget.session['end_time']}'),
      ]);
      sheet.appendRow([
        TextCellValue('Total Students'),
        IntCellValue(_records.length),
      ]);
      sheet.appendRow([TextCellValue('')]);

      // Header row
      sheet.appendRow([
        TextCellValue('No.'),
        TextCellValue('Name'),
        TextCellValue('Email'),
        TextCellValue('Check-in Time'),
        TextCellValue('GPS Verified'),
      ]);

      // Data rows
      for (int i = 0; i < _records.length; i++) {
        final r = _records[i];
        final checkIn = r['check_in_time'] != null
            ? timeFmt.format(DateTime.parse(r['check_in_time'] as String))
            : '--';
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(r['name'] as String),
          TextCellValue(r['email'] as String),
          TextCellValue(checkIn),
          TextCellValue(r['is_verified'] == true ? 'Yes' : 'No'),
        ]);
      }

      final bytes = ex.save()!;
      final subjectCode =
          (widget.session['subject_code'] as String).replaceAll(' ', '_');
      await downloadBytes('attendance_$subjectCode.xlsx', bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final date =
        DateTime.tryParse(widget.session['session_date'] as String? ?? '') ??
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
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
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
                          _summaryItem(
                              'Session\nStatus',
                              widget.session['is_active'] == true
                                  ? 'Active'
                                  : 'Closed',
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

                const SizedBox(height: 24),

                // Download buttons
                if (_exporting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(color: _blue),
                    ),
                  )
                else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Download PDF',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    onPressed: _records.isEmpty ? null : _downloadPdf,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Download Excel',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    onPressed: _records.isEmpty ? null : _downloadExcel,
                  ),
                ],

                const SizedBox(height: 20),
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
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
