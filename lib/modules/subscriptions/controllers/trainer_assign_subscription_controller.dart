import 'package:get/get.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/coaching/services/coaching_service.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

class TraineeOption {
  const TraineeOption({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();
}

class TrainerAssignSubscriptionController extends GetxController {
  TrainerAssignSubscriptionController(
    this._repository,
    this._coachingService,
  );

  final SubscriptionRepository _repository;
  final CoachingService _coachingService;

  final trainees = <TraineeOption>[].obs;
  final plans = <SubscriptionPlanModel>[].obs;
  final selectedTraineeId = RxnString();
  final selectedPlanId = RxnString();
  final startsAt = Rx<DateTime>(DateTime.now());
  final endsAt = Rx<DateTime>(DateTime.now().add(const Duration(days: 30)));
  final isLoading = true.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;

    try {
      final traineeRows = await _coachingService.fetchMyTrainees();
      trainees.assignAll(
        traineeRows.map(
          (row) => TraineeOption(
            id: row['id'] as String,
            firstName: row['first_name'] as String? ?? '',
            lastName: row['last_name'] as String? ?? '',
          ),
        ),
      );

      final trainerId = Get.find<AuthController>().currentUser.value?.id;
      if (trainerId != null) {
        final plansResult = await _repository.listTrainerPlans(trainerId);
        if (plansResult.failure == null) {
          plans.assignAll(plansResult.plans);
        }
      }

      if (trainees.isNotEmpty) {
        selectedTraineeId.value = trainees.first.id;
      }
      if (plans.isNotEmpty) {
        selectedPlanId.value = plans.first.id;
        _applyPlanDuration(plans.first);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void onPlanChanged(String? planId) {
    selectedPlanId.value = planId;
    final plan = plans.firstWhereOrNull((p) => p.id == planId);
    if (plan != null) {
      _applyPlanDuration(plan);
    }
  }

  void _applyPlanDuration(SubscriptionPlanModel plan) {
    final start = DateTime.now();
    startsAt.value = start;
    endsAt.value = start.add(Duration(days: plan.durationDays));
  }

  void setStarts(DateTime value) => startsAt.value = value;

  void setEnds(DateTime value) => endsAt.value = value;

  Future<void> assign() async {
    final traineeId = selectedTraineeId.value;
    final planId = selectedPlanId.value;

    if (traineeId == null || planId == null) {
      Get.snackbar('', 'subscription_assign_select_required'.tr);
      return;
    }
    if (!endsAt.value.isAfter(startsAt.value)) {
      Get.snackbar('', 'subscription_error_period'.tr);
      return;
    }

    isSubmitting.value = true;
    final result = await _repository.trainerAssignSubscription(
      traineeId: traineeId,
      planId: planId,
      startsAt: startsAt.value,
      endsAt: endsAt.value,
    );
    isSubmitting.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr);
      return;
    }

    Get.back(result: true);
  }
}
