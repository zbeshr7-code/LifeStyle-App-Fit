import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_enums.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_route_args.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

class TrainerSubscriptionEditController extends GetxController {
  TrainerSubscriptionEditController(this._repository, this.args);

  final SubscriptionRepository _repository;
  final TrainerSubscriptionEditArgs args;

  final startsAt = Rx<DateTime>(DateTime.now());
  final endsAt = Rx<DateTime>(DateTime.now());
  final isSaving = false.obs;
  final isCancelling = false.obs;

  TrainerSubscriberModel get subscriber => args.subscriber;

  bool get canCancel =>
      subscriber.status == SubscriptionStatus.active ||
      subscriber.status == SubscriptionStatus.pending;

  @override
  void onInit() {
    super.onInit();
    startsAt.value = subscriber.startsAt.toLocal();
    endsAt.value = subscriber.endsAt.toLocal();
  }

  void setStarts(DateTime value) => startsAt.value = value;

  void setEnds(DateTime value) => endsAt.value = value;

  Future<void> save() async {
    if (!endsAt.value.isAfter(startsAt.value)) {
      Get.snackbar('', 'subscription_error_period'.tr);
      return;
    }

    isSaving.value = true;
    final result = await _repository.trainerUpdateSubscriptionPeriod(
      subscriptionId: subscriber.subscriptionId,
      startsAt: startsAt.value.toUtc(),
      endsAt: endsAt.value.toUtc(),
    );
    isSaving.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr);
      return;
    }

    Get.back(result: true);
  }

  Future<void> cancel() async {
    if (!canCancel || isCancelling.value) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('subscription_cancel_confirm_title'.tr),
        content: Text('subscription_cancel_confirm_body'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('subscription_cancel_confirm_no'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('subscription_cancel_action'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isCancelling.value = true;
    final result = await _repository.trainerCancelSubscription(
      subscriber.subscriptionId,
    );
    isCancelling.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr);
      return;
    }

    Get.back(result: true);
  }
}
