import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'supabase_service.dart';
import '../../core/utils/error_handler.dart';

class WorkoutService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  Future<List<Map<String, dynamic>>> getWorkoutPlans(String traineeId) async {
    try {
      final response = await _client
          .from('workout_plans')
          .select('*, exercises(*)')
          .eq('trainee_id', traineeId)
          .order('day_of_week', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<bool> checkUserAccess(String userId) async {
    try {
      final response = await _client
          .from('user_access')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return false;
      return response['is_subscribed'] == true || response['access_granted_by_trainer'] == true;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
