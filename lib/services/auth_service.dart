import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Get current user role from profiles table
  Future<String?> getUserRole() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    return response['role'] as String?;
  }

  // Get current user name
  Future<String?> getUserName() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supabase
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .single();

    return response['name'] as String?;
  }

  // Logout
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}