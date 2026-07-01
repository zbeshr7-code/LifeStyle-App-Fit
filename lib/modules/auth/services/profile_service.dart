import 'package:soccer_sys/core/services/supabase_service.dart';

class ProfileService {
  ProfileService(this._supabaseService);

  final SupabaseService _supabaseService;

  Future<Map<String, dynamic>?> fetchProfileById(String userId) async {
    return _supabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    final userId = _supabaseService.client.auth.currentUser?.id;
    if (userId == null) return null;
    return fetchProfileById(userId);
  }

  Future<Map<String, dynamic>> updateDailyStepGoal(int goal) async {
    return updateProfile({'daily_step_goal': goal});
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) async {
    final userId = _supabaseService.client.auth.currentUser!.id;
    final payload = Map<String, dynamic>.from(fields)
      ..remove('id')
      ..remove('email')
      ..remove('role')
      ..remove('trainer_id');

    final result = await _supabaseService.client
        .from('profiles')
        .update(payload)
        .eq('id', userId)
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }
}
