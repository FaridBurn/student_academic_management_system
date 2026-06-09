import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final supabase = Supabase.instance.client;
  
  Future<String?> getProfileImageUrl() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      final response = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      
      return response?['avatar_url'];
    } catch (e) {
      print('Error getting profile image: $e');
      return null;
    }
  }
  
  // Simplified version without stream (easier to use)
  Future<void> updateProfileImage(String imageUrl) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);
    } catch (e) {
      print('Error updating profile image: $e');
    }
  }
  
  Future<void> removeProfileImage() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      await supabase
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', userId);
    } catch (e) {
      print('Error removing profile image: $e');
    }
  }
}