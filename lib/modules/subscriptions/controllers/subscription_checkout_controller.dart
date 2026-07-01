import 'package:get/get.dart';
import 'package:moyasar/moyasar.dart';
import 'package:soccer_sys/core/config/env_config.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/plan_payment_initiation_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';
import 'package:uuid/uuid.dart';

class SubscriptionCheckoutController extends GetxController {
  SubscriptionCheckoutController(this._repository, this.plan);

  final SubscriptionRepository _repository;
  final SubscriptionPlanModel plan;

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final paymentSession = Rxn<PlanPaymentInitiationModel>();
  final loadError = RxnString();

  bool get isFreePlan => plan.priceAmount <= 0;

  bool get canShowMoyasar =>
      !isFreePlan &&
      paymentSession.value != null &&
      EnvConfig.moyasarPublishableKey.isNotEmpty;

  PaymentConfig? get paymentConfig {
    final session = paymentSession.value;
    final key = EnvConfig.moyasarPublishableKey;
    if (session == null || key.isEmpty || session.isFree) return null;

    return PaymentConfig(
      publishableApiKey: key,
      amount: session.amountHalalas,
      description: plan.title,
      metadata: {'subscription_id': session.subscriptionId},
      givenID: const Uuid().v4(),
    );
  }

  @override
  void onInit() {
    super.onInit();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    isLoading.value = true;
    loadError.value = null;

    if (!isFreePlan && EnvConfig.moyasarPublishableKey.isEmpty) {
      isLoading.value = false;
      loadError.value = 'subscription_moyasar_key_missing';
      return;
    }

    final result = await _repository.initiatePlanPayment(plan.id);
    isLoading.value = false;

    if (result.failure != null) {
      loadError.value = result.failure!.message;
      return;
    }

    final session = result.session!;
    paymentSession.value = session;

    if (session.isFree) {
      final active = await _repository.getMyActiveSubscription();
      await _onSubscriptionActivated(subscription: active.subscription);
    }
  }

  Future<void> activateFreePlan() async {
    if (!isFreePlan || isSubmitting.value) return;
    isSubmitting.value = true;

    final result = await _repository.subscribeToPlan(plan.id);
    isSubmitting.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr);
      return;
    }

    await _onSubscriptionActivated(subscription: result.subscription);
  }

  Future<void> onPaymentResult(dynamic result) async {
    if (result is! PaymentResponse) return;

    switch (result.status) {
      case PaymentStatus.paid:
        await _verifyPaidPayment(result.id);
      case PaymentStatus.failed:
        Get.snackbar('', 'subscription_payment_failed'.tr);
      default:
        break;
    }
  }

  Future<void> _verifyPaidPayment(String paymentId) async {
    final session = paymentSession.value;
    if (session == null || isSubmitting.value) return;

    isSubmitting.value = true;
    final result = await _repository.verifyMoyasarPayment(
      subscriptionId: session.subscriptionId,
      paymentId: paymentId,
    );
    isSubmitting.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr);
      return;
    }

    await _onSubscriptionActivated(subscription: result.subscription);
  }

  Future<void> _onSubscriptionActivated({dynamic subscription}) async {
    if (Get.isRegistered<SubscriptionAccessController>()) {
      await Get.find<SubscriptionAccessController>().refresh();
    }

    Get.offNamed(
      AppRoutes.subscriptionSuccess,
      arguments: subscription,
    );
  }
}
