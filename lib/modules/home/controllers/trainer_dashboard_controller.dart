import 'package:get/get.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainer_clients_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_enums.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainer_subscription_revenue_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

class TrainerDashboardController extends GetxController {
  TrainerDashboardController(
    this._subscriptionRepository,
    this._authController,
  );

  final SubscriptionRepository _subscriptionRepository;
  final AuthController _authController;

  final status = Rx<RxStatus>(RxStatus.loading());
  final subscribers = <TrainerSubscriberModel>[].obs;
  final revenueThisMonth = Rxn<TrainerSubscriptionRevenueModel>();
  final planCount = 0.obs;
  final activePlanCount = 0.obs;

  int get clientCount {
    if (Get.isRegistered<TrainerClientsController>()) {
      return Get.find<TrainerClientsController>().clientCount;
    }
    return 0;
  }

  int get activeSubscriptionCount =>
      subscribers.where((s) => s.isActive).length;

  int get pendingSubscriptionCount => subscribers
      .where((s) => s.status == SubscriptionStatus.pending)
      .length;

  int get clientsWithoutActiveSub {
    final activeIds =
        subscribers.where((s) => s.isActive).map((s) => s.traineeId).toSet();
    return (clientCount - activeIds.length).clamp(0, clientCount);
  }

  List<TrainerSubscriberModel> get recentSubscribers {
    final sorted = List<TrainerSubscriberModel>.from(subscribers);
    sorted.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return b.endsAt.compareTo(a.endsAt);
    });
    return sorted.take(5).toList();
  }

  @override
  void onInit() {
    super.onInit();
    refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    status.value = RxStatus.loading();

    final trainerId = _authController.currentUser.value?.id;
    if (trainerId == null) {
      status.value = RxStatus.empty();
      return;
    }

    if (Get.isRegistered<TrainerClientsController>()) {
      await Get.find<TrainerClientsController>().loadTrainees();
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final subsResult = await _subscriptionRepository.trainerListSubscribers();
    final revenueResult = await _subscriptionRepository.trainerSubscriptionRevenue(
      from: monthStart,
      toExclusive: monthEnd,
    );
    final plansResult =
        await _subscriptionRepository.listTrainerPlans(trainerId);

    if (subsResult.failure != null) {
      status.value = RxStatus.error(subsResult.failure!.message);
      return;
    }

    subscribers.assignAll(subsResult.subscribers);
    revenueThisMonth.value = revenueResult.revenue;
    planCount.value = plansResult.plans.length;
    activePlanCount.value =
        plansResult.plans.where((p) => p.isActive).length;
    status.value = RxStatus.success();
  }
}

void ensureTrainerDashboardController() {
  final auth = Get.find<AuthController>();
  final user = auth.currentUser.value;
  if (user == null || !user.isTrainer) return;

  if (Get.isRegistered<TrainerDashboardController>()) return;

  Get.put<TrainerDashboardController>(
    TrainerDashboardController(
      Get.find<SubscriptionRepository>(),
      auth,
    ),
    permanent: true,
  );
}
