import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

enum SessionsState { idle, loading, loaded, error }

enum CreateSessionState { idle, loadingSubjects, submitting, success, error }

enum RecordsState { idle, loading, loaded, error }

enum CheckInState {
  idle,
  gettingLocation,
  submitting,
  success,
  invalidCode,
  outsideCampus,
  alreadyCheckedIn,
  locationDenied,
  error,
}

class AttendanceController extends ChangeNotifier {
  // — Lecturer sessions —
  SessionsState sessionsState = SessionsState.idle;
  List<Map<String, dynamic>> sessions = [];

  // — Create session —
  CreateSessionState createState = CreateSessionState.idle;
  List<Map<String, dynamic>> subjects = [];
  Map<String, dynamic>? createdSession;

  // — Attendance records (view + report) —
  RecordsState recordsState = RecordsState.idle;
  List<Map<String, dynamic>> attendanceRecords = [];

  // — Student check-in —
  CheckInState checkInState = CheckInState.idle;

  String? errorMessage;

  // ── Lecturer: load sessions ──────────────────────────────────────────────

  Future<void> loadSessions(String lecturerId) async {
    sessionsState = SessionsState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      sessions = await AttendanceService.getLecturerSessions(lecturerId);
      sessionsState = SessionsState.loaded;
    } catch (e) {
      errorMessage = 'Failed to load sessions: $e';
      sessionsState = SessionsState.error;
    }

    notifyListeners();
  }

  Future<void> toggleSession(int sessionId, bool isActive) async {
    try {
      await AttendanceService.toggleSession(sessionId, isActive);
    } catch (e) {
      errorMessage = 'Failed to update session: $e';
      notifyListeners();
    }
  }

  // ── Create session ───────────────────────────────────────────────────────

  Future<void> loadSubjects() async {
    createState = CreateSessionState.loadingSubjects;
    errorMessage = null;
    notifyListeners();

    try {
      subjects = await AttendanceService.getAllSubjects();
      createState = CreateSessionState.idle;
    } catch (e) {
      errorMessage = 'Failed to load subjects: $e';
      createState = CreateSessionState.error;
    }

    notifyListeners();
  }

  Future<void> createSession({
    required String lecturerId,
    required String subjectCode,
    required DateTime sessionDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    createState = CreateSessionState.submitting;
    errorMessage = null;
    createdSession = null;
    notifyListeners();

    try {
      createdSession = await AttendanceService.createSession(
        lecturerId: lecturerId,
        subjectCode: subjectCode,
        sessionDate: sessionDate,
        startTime: startTime,
        endTime: endTime,
      );
      createState = CreateSessionState.success;
    } catch (e) {
      errorMessage = 'Failed to create session: $e';
      createState = CreateSessionState.error;
    }

    notifyListeners();
  }

  void resetCreateState() {
    createState = CreateSessionState.idle;
    createdSession = null;
    errorMessage = null;
    notifyListeners();
  }

  // ── Attendance records ───────────────────────────────────────────────────

  Future<void> loadAttendanceRecords(int sessionId) async {
    recordsState = RecordsState.loading;
    notifyListeners();

    try {
      attendanceRecords =
          await AttendanceService.getSessionAttendance(sessionId);
      recordsState = RecordsState.loaded;
    } catch (_) {
      recordsState = RecordsState.error;
    }

    notifyListeners();
  }

  // ── Student: check-in ────────────────────────────────────────────────────

  Future<void> checkIn({
    required String code,
    required String studentId,
  }) async {
    double? lat, lng;

    if (!kIsWeb) {
      checkInState = CheckInState.gettingLocation;
      notifyListeners();

      try {
        final pos = await AttendanceService.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        checkInState = CheckInState.locationDenied;
        notifyListeners();
        return;
      }
    }

    checkInState = CheckInState.submitting;
    notifyListeners();

    try {
      final result = await AttendanceService.validateAndCheckIn(
        code: code,
        studentId: studentId,
        latitude: lat,
        longitude: lng,
      );

      switch (result) {
        case null:
          checkInState = CheckInState.success;
        case 'invalid_code':
          checkInState = CheckInState.invalidCode;
        case 'outside_campus':
          checkInState = CheckInState.outsideCampus;
        case 'already_checked_in':
          checkInState = CheckInState.alreadyCheckedIn;
        default:
          checkInState = CheckInState.error;
      }
    } catch (_) {
      checkInState = CheckInState.error;
    }

    notifyListeners();
  }

  void resetCheckInState() {
    checkInState = CheckInState.idle;
    notifyListeners();
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55
