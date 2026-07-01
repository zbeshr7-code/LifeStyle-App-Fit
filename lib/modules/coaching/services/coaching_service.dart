import 'package:soccer_sys/core/services/supabase_service.dart';

class CoachingService {
  CoachingService(this._supabaseService);

  final SupabaseService _supabaseService;

  Future<Map<String, dynamic>> assignTrainer(String trainerId) async {
    final result = await _supabaseService.client.rpc(
      'assign_trainer',
      params: {'p_trainer_id': trainerId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> fetchMyTrainer() async {
    final result =
        await _supabaseService.client.rpc('get_my_trainer');
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> fetchMyTrainees() async {
    final result = await _supabaseService.client.rpc('get_my_trainees');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>?> fetchTraineeProfile(String traineeId) async {
    final result = await _supabaseService.client
        .from('profiles')
        .select()
        .eq('id', traineeId)
        .maybeSingle();
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> listAvailableTrainers() async {
    final result =
        await _supabaseService.client.rpc('list_available_trainers');
    return List<Map<String, dynamic>>.from(result as List);
  }
}
