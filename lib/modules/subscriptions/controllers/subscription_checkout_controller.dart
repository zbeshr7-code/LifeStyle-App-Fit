import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/subscriptions/constants/store_product_catalog.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/plan_payment_initiation_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_plan_model.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';
import 'package:soccer_sys/modules/subscriptions/services/iap_service.dart';

class SubscriptionCheckoutController extends GetxController {
  SubscriptionCheckoutController(
    this._repository,
    this._iapService,
    this.plan,
  );

  final SubscriptionRepository _repository;
  final IapService _iapService;
  final SubscriptionPlanModel plan;

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final paymentSession = Rxn<PlanPaymentInitiationModel>();
  final storeProduct = Rxn<ProductDetails>();
  final loadError = RxnString();

  bool get isFreePlan => plan.priceAmount <= 0;

  bool get isIapSupported => !kIsWeb;

  bool get canPurchase =>
      isIapSupported &&
      !isFreePlan &&
      paymentSession.value != null &&
      storeProduct.value != null;

  String? get displayPrice =>
      storeProduct.value?.price ?? plan.priceAmount.toStringAsFixed(0);

  @override
  void onInit() {
    super.onInit();
    _iapService.listenPurchases(_onPurchaseUpdate);
    _initiatePayment();
  }

  @override
  void onClose() {
    _iapService.dispose();
    super.onClose();
  }

  Future<void> _initiatePayment() async {
    isLoading.value = true;
    loadError.value = null;

    if (!isFreePlan && !isIapSupported) {
      isLoading.value = false;
      loadError.value = 'subscription_iap_mobile_only';
      return;
    }

    final result = await _repository.initiatePlanPayment(plan.id);
    if (result.failure != null) {
      isLoading.value = false;
      loadError.value = result.failure!.message;
      return;
    }

    final session = result.session!;
    paymentSession.value = session;

    if (session.isFree) {
      isLoading.value = false;
      final active = await _repository.getMyActiveSubscription();
      if (active.subscription == null) {
        loadError.value = 'subscription_activate_failed';
        return;
      }
      await _onSubscriptionActivated(subscription: active.subscription);
      return;
    }

    final productId = _resolveStoreProductId(session);
    if (productId == null || productId.isEmpty) {
      isLoading.value = false;
      loadError.value = 'subscription_iap_product_missing';
      return;
    }

    if (!await _iapService.isStoreAvailable()) {
      isLoading.value = false;
      loadError.value = 'subscription_iap_unavailable';
      return;
    }

    final product = await _iapService.queryProduct(productId);
    isLoading.value = false;

    if (product == null) {
      loadError.value = 'subscription_iap_product_not_found';
      return;
    }

    storeProduct.value = product;
  }

  String? _resolveStoreProductId(PlanPaymentInitiationModel session) {
    final fromSession = session.storeProductId;
    if (fromSession != null && fromSession.isNotEmpty) return fromSession;

    final fromPlan = plan.storeProductId;
    if (fromPlan != null && fromPlan.isNotEmpty) return fromPlan;

    return StoreProductCatalog.forDurationDays(plan.durationDays);
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

  Future<void> purchasePlan() async {
    final product = storeProduct.value;
    if (product == null || isSubmitting.value) return;

    isSubmitting.value = true;
    final started = await _iapService.buy(product);
    if (!started) {
      isSubmitting.value = false;
      Get.snackbar('', 'subscription_payment_failed'.tr);
    }
  }

  Future<void> restorePurchases() async {
    if (!isIapSupported || isSubmitting.value) return;
    isSubmitting.value = true;
    await _iapService.restorePurchases();
    isSubmitting.value = false;
    Get.snackbar('', 'subscription_iap_restore_started'.tr);
  }

  Future<void> _onPurchaseUpdate(PurchaseDetails purchase) async {
    final session = paymentSession.value;
    final productId = session?.storeProductId;

    if (productId != null &&
        purchase.productID.isNotEmpty &&
        purchase.productID != productId) {
      return;
    }

    switch (purchase.status) {
      case PurchaseStatus.pending:
        return;
      case PurchaseStatus.error:
        isSubmitting.value = false;
        Get.snackbar('', 'subscription_payment_failed'.tr);
        await _iapService.completePurchase(purchase);
      case PurchaseStatus.canceled:
        isSubmitting.value = false;
        await _iapService.completePurchase(purchase);
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyStorePurchase(purchase);
    }
  }

  Future<void> _verifyStorePurchase(PurchaseDetails purchase) async {
    final session = paymentSession.value;
    if (session == null) {
      isSubmitting.value = false;
      return;
    }

    final transactionId = purchase.purchaseID ??
        purchase.transactionDate ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final result = await _repository.verifyStorePurchase(
      subscriptionId: session.subscriptionId,
      productId: purchase.productID,
      transactionId: transactionId,
      platform: IapService.platformLabel(),
      purchaseToken: purchase.verificationData.serverVerificationData,
      verificationData: purchase.verificationData.localVerificationData,
    );

    await _iapService.completePurchase(purchase);
    isSubmitting.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr);
      return;
    }

    await _onSubscriptionActivated(subscription: result.subscription);
  }

  Future<void> _onSubscriptionActivated({TraineeSubscriptionModel? subscription}) async {
    if (subscription == null) {
      loadError.value = 'subscription_activate_failed';
      return;
    }

    if (Get.isRegistered<SubscriptionAccessController>()) {
      await Get.find<SubscriptionAccessController>().refresh();
    }

    Get.offNamed(
      AppRoutes.subscriptionSuccess,
      arguments: subscription,
    );
  }
}
