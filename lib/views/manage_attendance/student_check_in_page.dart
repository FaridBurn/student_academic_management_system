import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/attendance_service.dart';

class StudentCheckInPage extends StatefulWidget {
  const StudentCheckInPage({super.key});

  @override
  State<StudentCheckInPage> createState() => _StudentCheckInPageState();
}

class _StudentCheckInPageState extends State<StudentCheckInPage> {
  static const _blue = Color(0xFF0288D1);

  final _codeCtrl = TextEditingController();
  bool _submitting = false;
  String? _gpsStatus;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-character code.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _gpsStatus = kIsWeb ? null : 'Getting your location...';
    });

    final studentId = Supabase.instance.client.auth.currentUser!.id;
    double? lat, lng;

    if (!kIsWeb) {
      try {
        final pos = await AttendanceService.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
        setState(() => _gpsStatus = 'Location acquired ✓');
      } catch (e) {
        setState(() {
          _submitting = false;
          _gpsStatus = null;
        });
        if (mounted) {
          _showResult('error',
              'Location access is required to check in.\nPlease enable GPS and try again.');
        }
        return;
      }
    }

    try {
      final error = await AttendanceService.validateAndCheckIn(
        code: code,
        studentId: studentId,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _gpsStatus = null;
      });

      if (error == null) {
        _showResult('success', 'Attendance recorded successfully!');
        _codeCtrl.clear();
      } else if (error == 'invalid_code') {
        _showResult('error',
            'Invalid or expired code.\nPlease check the code and try again.');
      } else if (error == 'outside_campus') {
        _showResult('location',
            'Location Verification Failed.\nYou must be within campus to check in.');
      } else if (error == 'already_checked_in') {
        _showResult('info', 'You have already checked in for this session.');
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _gpsStatus = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showResult(String type, String message) {
    final isSuccess = type == 'success';
    final isLocation = type == 'location';
    final isInfo = type == 'info';

    Color color;
    IconData icon;
    if (isSuccess) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (isLocation) {
      color = Colors.orange;
      icon = Icons.location_off;
    } else if (isInfo) {
      color = Colors.blue;
      icon = Icons.info;
    } else {
      color = Colors.red;
      icon = Icons.error;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 56),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text('Check Attendance',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner,
                  size: 48, color: _blue),
            ),
            const SizedBox(height: 20),

            const Text('Enter Attendance Code',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Ask your lecturer for the 6-character session code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 32),

            // Code input
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • • • •',
                hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 28,
                    letterSpacing: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
              ),
              onChanged: (v) {
                if (v != v.toUpperCase()) {
                  _codeCtrl.value = _codeCtrl.value.copyWith(
                    text: v.toUpperCase(),
                    selection: TextSelection.collapsed(offset: v.length),
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // GPS status
            if (!kIsWeb && _gpsStatus != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _blue),
                    ),
                    const SizedBox(width: 10),
                    Text(_gpsStatus!,
                        style:
                            const TextStyle(color: _blue, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (kIsWeb) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GPS verification is disabled on web. Use the mobile app for full attendance validation.',
                        style: TextStyle(
                            color: Colors.orange.shade800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Check-in button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  _submitting ? 'Checking in...' : 'Check In',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: _submitting ? null : _checkIn,
              ),
            ),

            const SizedBox(height: 24),

            // GPS info (mobile only)
            if (!kIsWeb)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: _blue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your GPS location will be captured to verify you are on campus.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
