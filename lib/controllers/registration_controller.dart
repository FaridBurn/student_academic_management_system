import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject.dart';
import '../models/student.dart';

class RegistrationController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Subject> _subjects = [];
  List<Subject> _filteredSubjects = [];
  List<Subject> _cartItems = [];
  bool _isLoading = false;
  Student? _currentStudent;

  List<Subject> get filteredSubjects => _filteredSubjects;
  List<Subject> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  Student? get currentStudent => _currentStudent;
  int get totalCartCredits => _cartItems.fold(0, (sum, item) => sum + item.credit_hours);

  // LOGIN - Fixed version (removed duplicate code)
  Future<bool> loginUser(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // ignore: avoid_print
      print('Login attempt: email=$email, password=$password');
      
      final response = await _supabase
          .from('students')
          .select()
          .eq('stu_email', email)
          .eq('stu_password', password)
          .maybeSingle();
      // ignore: avoid_print
      print('Response from Supabase: $response');

      if (response != null) {
        _currentStudent = Student.fromJson(response);
        // ignore: avoid_print
        print('Student found: ${_currentStudent!.stu_name}');
        
        if (_currentStudent!.stu_blocked) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // ignore: avoid_print
        print('No student found with these credentials');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error during login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

<<<<<<< HEAD
  void setCurrentStudent(Student student) {
      _currentStudent = student;
    notifyListeners();
  }

=======
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55
  // FETCH ALL SUBJECTS
  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('subjects')
          .select()
          .order('sub_code');
      
      _subjects = (response as List)
          .map((json) => Subject.fromJson(json))
          .toList();
      
      _filteredSubjects = List.from(_subjects);
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // FILTER SUBJECTS
  void filterSubjects(String query) {
    if (query.isEmpty) {
      _filteredSubjects = List.from(_subjects);
    } else {
      _filteredSubjects = _subjects.where((subject) {
        return subject.sub_code.toLowerCase().contains(query.toLowerCase()) ||
               subject.sub_name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  // ADD TO CART (with validation)
  Future<bool> addToCart(Subject subject) async {
    // Check if already in cart
    if (_cartItems.any((item) => item.subjectID == subject.subjectID)) {
      return false;
    }
    
    // Check credit limit (max 20)
    if (totalCartCredits + subject.credit_hours > 20) {
      return false;
    }
    
    _cartItems.add(subject);
    notifyListeners();
    return true;
  }

  // REMOVE FROM CART
  void removeFromCart(Subject subject) {
    _cartItems.removeWhere((item) => item.subjectID == subject.subjectID);
    notifyListeners();
  }

  // CLEAR CART
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // SUBMIT REGISTRATION
<<<<<<< HEAD
Future<bool> submitRegistration(String semester, String academicYear) async {
  print('submitRegistration called. Student: ${_currentStudent?.studentID}, Cart items: ${_cartItems.length}');
  if (_currentStudent == null || _cartItems.isEmpty) {
    print('No student or cart empty');
    return false;
  }

  _isLoading = true;
  notifyListeners();

  try {
    for (var subject in _cartItems) {
      print('Inserting subject: ${subject.subjectID}');
      await _supabase.from('registrations').insert({
        'studentid': _currentStudent!.studentID,
        'subjectid': subject.subjectID,
        'semester': semester,
        'academic_year': academicYear,
        'status': 'Pending',
        'registered_at': DateTime.now().toIso8601String(),
      });
      print('Insert successful for subject ${subject.subjectID}');
    }

    _cartItems.clear();
    _isLoading = false;
    notifyListeners();
    print('Registration successful, returning true');
    return true;
  } catch (e) {
    print('Error in submitRegistration: $e');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  // FETCH TIMETABLE
Future<List<Map<String, dynamic>>> fetchTimetable(String semester, String academicYear) async {
  if (_currentStudent == null) return [];

  try {
    final response = await _supabase
        .from('registrations')
        .select('''
          registrationid,
          status,
          subjects:subjectid (subjectid, sub_code, sub_name, credit_hours)
        ''')
        .eq('studentid', _currentStudent!.studentID)
        .eq('semester', semester)
        .eq('academic_year', academicYear)
        .eq('status', 'Approved');

    return response;
  } catch (e) {
    debugPrint('Error fetching timetable: $e');
    return [];
  }
}
=======
  Future<bool> submitRegistration(String semester, String academicYear) async {
    if (_currentStudent == null || _cartItems.isEmpty) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      for (var subject in _cartItems) {
        await _supabase.from('registrations').insert({
          'studentID': _currentStudent!.studentID,
          'subjectID': subject.subjectID,
          'semester': semester,
          'academic_year': academicYear,
          'status': 'Pending',
          'registered_at': DateTime.now().toIso8601String(),
        });
      }
      
      _cartItems.clear();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submitting registration: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // FETCH TIMETABLE
  Future<List<Map<String, dynamic>>> fetchTimetable(String semester, String academicYear) async {
    if (_currentStudent == null) return [];
    
    try {
      final response = await _supabase
          .from('registrations')
          .select('''
            registrationID,
            status,
            subjects:subjectID (subjectID, sub_code, sub_name, credit_hours)
          ''')
          .eq('studentID', _currentStudent!.studentID)
          .eq('semester', semester)
          .eq('academic_year', academicYear)
          .eq('status', 'Approved');
      
      return response;
    } catch (e) {
      debugPrint('Error fetching timetable: $e');
      return [];
    }
  }
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55
  
  // LOGOUT
  void logout() {
    _currentStudent = null;
    _subjects = [];
    _filteredSubjects = [];
    _cartItems = [];
    notifyListeners();
  }
}