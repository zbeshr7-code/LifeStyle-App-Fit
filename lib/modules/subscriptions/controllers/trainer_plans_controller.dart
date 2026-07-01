import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_route_args.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainer_subscription_revenue_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

enum RevenueDatePreset { all, thisMonth, last30Days, custom }

class TrainerPlansController extends GetxController {
  TrainerPlansController(this._repository);

  final SubscriptionRepository _repository;

  final plans = <SubscriptionPlanModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.loading());
  final errorMessage = ''.obs;
  final revenue = Rxn<TrainerSubscriptionRevenueModel>();
  final isLoadingRevenue = false.obs;
  final revenuePreset = RevenueDatePreset.all.obs;
  final customFrom = Rxn<DateTime>();
  final customTo = Rxn<DateTime>();

  String get customRangeLabel {
    if (revenuePreset.value != RevenueDatePreset.custom) {
      return 'subscription_revenue_filter_custom'.tr;
    }
    final from = customFrom.value;
    final to = customTo.value;
    if (from == null || to == null) {
      return 'subscription_revenue_filter_custom'.tr;
    }
    final fmt = DateFormat.Md();
    return '${fmt.format(from)} – ${fmt.format(to)}';
  }

  @override
  void onInit() {
    super.onInit();
    loadPlans();
    loadRevenue();
  }

  (DateTime? from, DateTime? toExclusive) _revenueRange() {
    final now = DateTime.now();
    switch (revenuePreset.value) {
      case RevenueDatePreset.all:
        return (null, null);
      case RevenueDatePreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final endExclusive = DateTime(now.year, now.month + 1, 1);
        return (start, endExclusive);
      case RevenueDatePreset.last30Days:
        final today = DateTime(now.year, now.month, now.day);
        return (
          today.subtract(const Duration(days: 30)),
          today.add(const Duration(days: 1)),
        );
      case RevenueDatePreset.custom:
        final from = customFrom.value;
        final to = customTo.value;
        if (from == null || to == null) return (null, null);
        final start = DateTime(from.year, from.month, from.day);
        final endExclusive =
            DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
        return (start, endExclusive);
    }
  }

  Future<void> loadRevenue() async {
    isLoadingRevenue.value = true;
    final range = _revenueRange();
    final result = await _repository.trainerSubscriptionRevenue(
      from: range.$1,
      toExclusive: range.$2,
    );
    isLoadingRevenue.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    revenue.value = result.revenue;
  }

  void setRevenuePreset(RevenueDatePreset preset) {
    revenuePreset.value = preset;
    loadRevenue();
  }

  Future<void> pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: customFrom.value != null && customTo.value != null
          ? DateTimeRange(start: customFrom.value!, end: customTo.value!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
    );
    if (picked == null) return;
    customFrom.value = picked.start;
    customTo.value = picked.end;
    revenuePreset.value = RevenueDatePreset.custom;
    await loadRevenue();
  }

  Future<void> loadPlans() async {
    status.value = RxStatus.loading();
    errorMessage.value = '';
    final trainerId = Get.find<AuthController>().currentUser.value?.id;
    if (trainerId == null) {
      errorMessage.value = 'profile_not_found';
      status.value = RxStatus.error('profile_not_found');
      return;
    }

    final result = await _repository.listTrainerPlans(trainerId);
    if (result.failure != null) {
      errorMessage.value = result.failure!.message;
      status.value = RxStatus.error(result.failure!.message);
      return;
    }
    plans.assignAll(result.plans);
    status.value = plans.isEmpty ? RxStatus.empty() : RxStatus.success();
  }

  Future<void> refreshAll() async {
    await Future.wait([loadPlans(), loadRevenue()]);
  }

  void openCreatePlan() {
    Get.toNamed(
      AppRoutes.trainerPlanForm,
      arguments: const TrainerPlanFormArgs(),
    )?.then((_) => loadPlans());
  }

  void openEditPlan(SubscriptionPlanModel plan) {
    Get.toNamed(
      AppRoutes.trainerPlanForm,
      arguments: TrainerPlanFormArgs(plan: plan),
    )?.then((_) => loadPlans());
  }

  Future<void> deactivatePlan(SubscriptionPlanModel plan) async {
    final failure = await _repository.deactivatePlan(plan.id);
    if (failure != null) {
      Get.snackbar('', failure.message.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await loadPlans();
  }
}
