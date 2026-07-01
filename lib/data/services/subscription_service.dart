import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'supabase_service.dart';
import '../../core/utils/error_handler.dart';

class SubscriptionService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  Future<List<Map<String, dynamic>>> getActivePlans() async {
    try {
      final response = await _client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<void> subscribeToPlan(String userId, String planId) async {
    try {
      // In a real app, this would happen after payment confirmation
      await _client.from('user_access').update({
        'is_subscribed': true,
        // Calculate expiry date based on plan duration in the repo/logic
      }).eq('user_id', userId);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
