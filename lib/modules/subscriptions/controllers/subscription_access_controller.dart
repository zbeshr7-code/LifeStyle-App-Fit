import 'package:get/get.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

class SubscriptionAccessController extends GetxController {
  SubscriptionAccessController(this._repository);

  final SubscriptionRepository _repository;

  final activeSubscription = Rxn<TraineeSubscriptionModel>();
  final featuredPlans = <SubscriptionPlanModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  bool get needsTrainer {
    final user = Get.find<AuthController>().currentUser.value;
    return user != null && user.isTrainee && !user.hasTrainer;
  }

  bool get hasAccess => activeSubscription.value?.isActive ?? false;

  bool get needsSubscription {
    if (needsTrainer) return false;
    final user = Get.find<AuthController>().currentUser.value;
    if (user == null || !user.isTrainee) return false;
    return !hasAccess;
  }

  String? get trainerId =>
      Get.find<AuthController>().currentUser.value?.trainerId;

  @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().currentUser, (_) => refresh());
  }

  @override
  Future<void> refresh() async {
    final user = Get.find<AuthController>().currentUser.value;
    if (user == null || !user.isTrainee) {
      activeSubscription.value = null;
      featuredPlans.clear();
      return;
    }

    if (!user.hasTrainer) {
      activeSubscription.value = null;
      featuredPlans.clear();
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final subResult = await _repository.getMyActiveSubscription();
    if (subResult.failure != null) {
      errorMessage.value = subResult.failure!.message.tr;
    } else {
      activeSubscription.value = subResult.subscription;
    }

    final plansResult = await _repository.listTrainerPlans(user.trainerId!);
    if (plansResult.failure == null) {
      featuredPlans.assignAll(
        plansResult.plans.where((p) => p.isActive).toList(),
      );
    }

    isLoading.value = false;
  }
}
