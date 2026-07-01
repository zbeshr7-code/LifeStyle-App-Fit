import '../services/subscription_service.dart';
import 'package:get/get.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionRepository {
  final SubscriptionService _service = Get.find<SubscriptionService>();

  Future<List<SubscriptionPlan>> getPlans() async {
    final data = await _service.getActivePlans();
    return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
  }

  Future<void> subscribe(String userId, String planId) async {
    await _service.subscribeToPlan(userId, planId);
  }
}
