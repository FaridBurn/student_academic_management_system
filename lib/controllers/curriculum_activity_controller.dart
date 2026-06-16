import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/curriculum_activity.dart';
import '../models/activity_claim.dart';  // Now this exists!

class CurriculumController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<CurriculumActivityModel> _activities = [];
  List<CurriculumActivityModel> _filteredActivities = [];
  List<ActivityClaimModel> _myClaims = [];
  List<ActivityClaimModel> _pendingClaims = [];
  List<ActivityClaimModel> _allClaims = [];
  bool _isLoading = false;
  String _currentUserId = '';
  String _currentUserRole = '';

  // Getters
  List<CurriculumActivityModel> get filteredActivities => _filteredActivities;
  List<ActivityClaimModel> get myClaims => _myClaims;
  List<ActivityClaimModel> get pendingClaims => _pendingClaims;
  List<ActivityClaimModel> get allClaims => _allClaims;
  bool get isLoading => _isLoading;
  int get totalEarnedCredits => _myClaims
      .where((claim) => claim.isApproved)
      .fold(0, (sum, claim) => sum + claim.hours);

  // Initialize controller with user info
  void initialize(String userId, String role) {
    _currentUserId = userId;
    _currentUserRole = role;
    notifyListeners();
  }

  // ============ ACTIVITY MANAGEMENT ============

  Future<void> fetchAvailableActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('curriculum_activities')
          .select()
          .eq('is_active', true)
          .order('name');

      _activities = (response as List)
          .map((json) => CurriculumActivityModel.fromMap(json))
          .toList();
      
      _filteredActivities = List.from(_activities);
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void filterActivities(String query, String? category) {
    List<CurriculumActivityModel> temp = List.from(_activities);
    
    if (query.isNotEmpty) {
      temp = temp.where((activity) {
        return activity.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    
    if (category != null && category.isNotEmpty) {
      temp = temp.where((activity) => activity.category == category).toList();
    }
    
    _filteredActivities = temp;
    notifyListeners();
  }

  // Add new activity - Only Pusat Adab
  Future<bool> addActivity({
    required String activityName,
    required String activityType,
    required int hours,
    required String description,
  }) async {
    if (_currentUserRole != 'pusat_adab') return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('curriculum_activities').insert({
        'name': activityName,
        'category': activityType,
        'hours': hours,
        'description': description,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await fetchAvailableActivities();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding activity: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============ CLAIMS MANAGEMENT ============

  // Submit claim for credit hours
  Future<bool> submitClaim({
    required int activityId,
    required String remark,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if already exists
      final existingClaim = await _supabase
          .from('curriculum_claims')
          .select()
          .eq('profile_id', _currentUserId)
          .eq('activity_id', activityId)
          .maybeSingle();
      
      if (existingClaim != null && existingClaim['status'] == 'approved') {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Update or insert
      if (existingClaim != null) {
        await _supabase
            .from('curriculum_claims')
            .update({
              'status': 'pending',
              'remark': remark,
              'claimed_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingClaim['id']);
      } else {
        await _supabase.from('curriculum_claims').insert({
          'profile_id': _currentUserId,
          'activity_id': activityId,
          'status': 'pending',
          'remark': remark,
          'joined_at': DateTime.now().toIso8601String(),
          'claimed_at': DateTime.now().toIso8601String(),
        });
      }
      
      await fetchMyClaims();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submitting claim: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch all claims for current student
  Future<void> fetchMyClaims() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('curriculum_claims')
          .select('''
            id,
            status,
            remark,
            joined_at,
            claimed_at,
            created_at,
            curriculum_activities!activity_id (
              id,
              name,
              category,
              hours
            )
          ''')
          .eq('profile_id', _currentUserId)
          .order('claimed_at', ascending: false);
      
      _myClaims = (response as List)
          .map((json) => ActivityClaimModel.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching my claims: $e');
      _myClaims = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch pending claims for verification (Pusat Adab)
  Future<void> fetchPendingClaims() async {
    if (_currentUserRole != 'pusat_adab') return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('curriculum_claims')
          .select('''
            id,
            status,
            remark,
            joined_at,
            claimed_at,
            created_at,
            profile_id,
            profiles!profile_id (
              id,
              email,
              name
            ),
            curriculum_activities!activity_id (
              id,
              name,
              category,
              hours
            )
          ''')
          .eq('status', 'pending')
          .order('claimed_at', ascending: false);
      
      _pendingClaims = (response as List)
          .map((json) => ActivityClaimModel.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending claims: $e');
      _pendingClaims = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Verify claim - Approve or Reject
  Future<bool> verifyClaim(int claimId, String status, {String? remarks}) async {
    if (_currentUserRole != 'pusat_adab') return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase
          .from('curriculum_claims')
          .update({
            'status': status,
            'remark': remarks,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', claimId);
      
      await fetchPendingClaims();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error verifying claim: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear all data (on logout)
  void clearData() {
    _activities = [];
    _filteredActivities = [];
    _myClaims = [];
    _pendingClaims = [];
    _allClaims = [];
    _currentUserId = '';
    _currentUserRole = '';
    notifyListeners();
  }
}