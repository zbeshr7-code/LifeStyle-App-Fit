import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_enums.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_route_args.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

class TrainerPlanFormController extends GetxController {
  TrainerPlanFormController(this._repository, this.args);

  final SubscriptionRepository _repository;
  final TrainerPlanFormArgs args;

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController customDaysController;

  final features = <String>[].obs;
  final featureInput = ''.obs;
  final durationPreset = PlanDurationPreset.oneMonth.obs;
  final isFeatured = false.obs;
  final isSaving = false.obs;

  bool get isEditing => args.plan != null;

  @override
  void onInit() {
    super.onInit();
    final plan = args.plan;
    titleController = TextEditingController(text: plan?.title ?? '');
    descriptionController = TextEditingController(text: plan?.description ?? '');
    priceController = TextEditingController(
      text: plan != null ? plan.priceAmount.toStringAsFixed(0) : '',
    );
    customDaysController = TextEditingController(
      text: plan != null && plan.durationDays != 30 && plan.durationDays != 90
          ? '${plan.durationDays}'
          : '30',
    );

    if (plan != null) {
      features.assignAll(plan.features);
      isFeatured.value = plan.isFeatured;
      durationPreset.value = switch (plan.durationDays) {
        30 => PlanDurationPreset.oneMonth,
        90 => PlanDurationPreset.threeMonths,
        _ => PlanDurationPreset.custom,
      };
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    customDaysController.dispose();
    super.onClose();
  }

  void setPreset(PlanDurationPreset preset) => durationPreset.value = preset;

  void addFeature() {
    final text = featureInput.value.trim();
    if (text.isEmpty) return;
    features.add(text);
    featureInput.value = '';
  }

  void removeFeature(int index) {
    if (index >= 0 && index < features.length) {
      features.removeAt(index);
    }
  }

  int get _durationDays {
    final preset = durationPreset.value;
    if (preset == PlanDurationPreset.custom) {
      return int.tryParse(customDaysController.text.trim()) ?? 0;
    }
    return preset.days;
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar('', 'subscription_error_title'.tr);
      return;
    }

    final price = double.tryParse(priceController.text.trim()) ?? -1;
    if (price < 0) {
      Get.snackbar('', 'subscription_error_price'.tr);
      return;
    }

    final days = _durationDays;
    if (days <= 0) {
      Get.snackbar('', 'subscription_error_duration'.tr);
      return;
    }

    if (features.isEmpty) {
      Get.snackbar('', 'subscription_error_features'.tr);
      return;
    }

    isSaving.value = true;
    final result = await _repository.upsertPlan(
      planId: args.plan?.id,
      title: title,
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      priceAmount: price,
      durationDays: days,
      features: features.toList(),
      isFeatured: isFeatured.value,
    );
    isSaving.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr);
      return;
    }

    Get.back(result: true);
  }
}
