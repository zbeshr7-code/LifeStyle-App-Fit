import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';

/// Redirects trainees without an active subscription away from protected routes.
class SubscriptionRequiredMiddleware extends GetMiddleware {
  static const _exempt = {
    AppRoutes.home,
    AppRoutes.chatRoom,
    AppRoutes.chooseTrainer,
    AppRoutes.subscriptionPlans,
    AppRoutes.subscriptionCheckout,
    AppRoutes.subscriptionSuccess,
    AppRoutes.profileEdit,
    AppRoutes.callActive,
  };

  @override
  RouteSettings? redirect(String? route) {
    if (route != null && _exempt.contains(route)) return null;

    if (!Get.isRegistered<AuthController>()) return null;
    final user = Get.find<AuthController>().currentUser.value;
    if (user == null || !user.isTrainee) return null;

    if (!Get.isRegistered<SubscriptionAccessController>()) return null;
    final access = Get.find<SubscriptionAccessController>();

    if (access.needsTrainer) {
      return const RouteSettings(name: AppRoutes.chooseTrainer);
    }
    if (access.needsSubscription) {
      return const RouteSettings(name: AppRoutes.subscriptionPlans);
    }
    return null;
  }
}
