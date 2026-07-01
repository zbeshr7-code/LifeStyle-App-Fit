import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'supabase_service.dart';
import '../../core/utils/error_handler.dart';

class StepsService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  Future<void> syncSteps(String userId, int steps, double distance, double calories) async {
    try {
      await _client.from('daily_activity').upsert({
        'user_id': userId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'steps': steps,
        'distance': distance,
        'calories': calories,
      });
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<Map<String, dynamic>> getActivityStats(String userId) async {
    try {
      // Mocked logic for now
      return {
        'streak_days': 12,
        'average_steps': 8240,
      };
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
