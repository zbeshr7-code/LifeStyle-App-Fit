import 'package:get/get.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/models/subscription_plan_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/utils/error_handler.dart';

class SubscriptionController extends GetxController {
  final SubscriptionRepository _repository = SubscriptionRepository();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;
      final data = await _repository.getPlans();
      plans.assignAll(data);
    } catch (e) {
      ErrorHandler.showErrorSnackbar(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> subscribe(String planId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;
      
      isLoading.value = true;
      await _repository.subscribe(userId, planId);
      Get.back(); // Go back after success
      Get.snackbar('success'.tr, 'subscription_success'.tr);
    } catch (e) {
      ErrorHandler.showErrorSnackbar(e);
    } finally {
      isLoading.value = false;
    }
  }
}
