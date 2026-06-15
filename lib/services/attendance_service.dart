import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  static final _db = Supabase.instance.client;

  // UMPSA Pekan Campus geofence — update lat/lng to match your actual campus
  static const double campusLat = 3.546771;
  static const double campusLng = 103.427737;
  static const double campusRadiusMeters = 500.0;

  // Excludes visually confusable characters (0/O, 1/I/L)
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generateCode() {
    final rng = Random.secure();
    return List.generate(
      6,
      (_) => _codeChars[rng.nextInt(_codeChars.length)],
    ).join();
  }

  static double _haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static bool isWithinCampus(double lat, double lng) =>
      _haversineMeters(lat, lng, campusLat, campusLng) <= campusRadiusMeters;

  static Future<Position> getCurrentPosition() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception('location_permission_denied');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static Future<Map<String, dynamic>> createSession({
    required String lecturerId,
    required String subjectCode,
    required DateTime sessionDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    String p(int n) => n.toString().padLeft(2, '0');
    final code = generateCode();
    final data = await _db
        .from('attendance_sessions')
        .insert({
          'lecturer_id': lecturerId,
          'subject_code': subjectCode,
          'session_date':
              '${sessionDate.year}-${p(sessionDate.month)}-${p(sessionDate.day)}',
          'start_time': '${p(startTime.hour)}:${p(startTime.minute)}:00',
          'end_time': '${p(endTime.hour)}:${p(endTime.minute)}:00',
          'attendance_code': code,
          'is_active': true,
        })
        .select()
        .single();
    return data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getLecturerSessions(
    String lecturerId,
  ) async {
    final data = await _db
        .from('attendance_sessions')
        .select()
        .eq('lecturer_id', lecturerId)
        .order('created_at', ascending: false);
    final sessions = List<Map<String, dynamic>>.from(data);
    await _closeExpiredSessions(sessions);
    // Re-fetch so callers see updated is_active values after auto-close.
    final refreshed = await _db
        .from('attendance_sessions')
        .select()
        .eq('lecturer_id', lecturerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(refreshed);
  }

  /// Closes any active session whose end time on session_date has passed.
  static Future<void> _closeExpiredSessions(
    List<Map<String, dynamic>> sessions,
  ) async {
    final now = DateTime.now();
    for (final s in sessions) {
      if (s['is_active'] != true) continue;
      final endDt = _sessionEndDateTime(s);
      if (endDt != null && now.isAfter(endDt)) {
        await toggleSession(s['session_id'] as int, false);
      }
    }
  }

  /// Parses session_date + end_time into a DateTime, or null on failure.
  static DateTime? _sessionEndDateTime(Map<String, dynamic> s) {
    final dateStr = s['session_date'] as String?;
    final endStr = s['end_time'] as String?;
    if (dateStr == null || endStr == null) return null;
    try {
      final date = DateTime.parse(dateStr);
      final parts = endStr.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the end DateTime of the soonest active session that hasn't
  /// expired yet, or null if there are none.
  static DateTime? nextSessionExpiry(List<Map<String, dynamic>> sessions) {
    final now = DateTime.now();
    DateTime? soonest;
    for (final s in sessions) {
      if (s['is_active'] != true) continue;
      final endDt = _sessionEndDateTime(s);
      if (endDt == null || !endDt.isAfter(now)) continue;
      if (soonest == null || endDt.isBefore(soonest)) soonest = endDt;
    }
    return soonest;
  }

  static Future<List<Map<String, dynamic>>> getSessionAttendance(
    int sessionId,
  ) async {
    final records = await _db
        .from('attendance_records')
        .select(
          'attendance_id, student_id, check_in_time, gps_latitude, gps_longitude, is_verified',
        )
        .eq('session_id', sessionId)
        .order('check_in_time', ascending: true);

    final List<Map<String, dynamic>> enriched = [];
    for (final r in records as List) {
      final profile = await _db
          .from('profiles')
          .select('name, email')
          .eq('id', r['student_id'])
          .maybeSingle();
      enriched.add({
        ...r,
        'name': profile?['name'] ?? 'Unknown',
        'email': profile?['email'] ?? '',
      });
    }
    return enriched;
  }

  static Future<int> getAttendanceCount(int sessionId) async {
    final data = await _db
        .from('attendance_records')
        .select('attendance_id')
        .eq('session_id', sessionId);
    return (data as List).length;
  }

  /// Returns null on success, or one of:
  /// 'invalid_code' | 'outside_campus' | 'already_checked_in'
  static Future<String?> validateAndCheckIn({
    required String code,
    required String studentId,
    double? latitude,
    double? longitude,
  }) async {
    final session = await _db
        .from('attendance_sessions')
        .select()
        .eq('attendance_code', code.toUpperCase().trim())
        .eq('is_active', true)
        .maybeSingle();

    if (session == null) return 'invalid_code';

    final existing = await _db
        .from('attendance_records')
        .select()
        .eq('session_id', session['session_id'])
        .eq('student_id', studentId)
        .maybeSingle();

    if (existing != null) return 'already_checked_in';

    if (!kIsWeb && latitude != null && longitude != null) {
      if (!isWithinCampus(latitude, longitude)) return 'outside_campus';
    }

    await _db.from('attendance_records').insert({
      'session_id': session['session_id'],
      'student_id': studentId,
      'gps_latitude': latitude,
      'gps_longitude': longitude,
      'is_verified': !kIsWeb && latitude != null,
    });

    return null;
  }

  static Future<List<Map<String, dynamic>>> getAllSubjects() async {
    final data = await _db
        .from('subjects')
        .select('subjectid, sub_code, sub_name, sub_semester')
        .order('sub_code', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> toggleSession(int sessionId, bool isActive) async {
    await _db
        .from('attendance_sessions')
        .update({'is_active': isActive})
        .eq('session_id', sessionId);
  }
}