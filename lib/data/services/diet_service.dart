import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'supabase_service.dart';
import '../../core/utils/error_handler.dart';

class DietService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  Future<Map<String, dynamic>?> getMealPlan(String traineeId) async {
    try {
      final response = await _client
          .from('meal_plans')
          .select()
          .eq('trainee_id', traineeId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
