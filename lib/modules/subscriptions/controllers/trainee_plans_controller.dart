import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_route_args.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

class TraineePlansController extends GetxController {
  TraineePlansController(this._repository);

  final SubscriptionRepository _repository;

  final plans = <SubscriptionPlanModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.loading());
  final errorMessage = ''.obs;

  String? get trainerId =>
      Get.find<AuthController>().currentUser.value?.trainerId;

  @override
  void onInit() {
    super.onInit();
    loadPlans();
  }

  Future<void> loadPlans() async {
    final tid = trainerId;
    if (tid == null || tid.isEmpty) {
      status.value = RxStatus.empty();
      return;
    }

    status.value = RxStatus.loading();
    final result = await _repository.listTrainerPlans(tid);
    if (result.failure != null) {
      errorMessage.value = result.failure!.message;
      status.value = RxStatus.error(result.failure!.message);
      return;
    }

    plans.assignAll(result.plans.where((p) => p.isActive));
    status.value = plans.isEmpty ? RxStatus.empty() : RxStatus.success();
  }

  void openCheckout(SubscriptionPlanModel plan) {
    Get.toNamed(
      AppRoutes.subscriptionCheckout,
      arguments: SubscriptionCheckoutArgs(plan: plan),
    );
  }
}
