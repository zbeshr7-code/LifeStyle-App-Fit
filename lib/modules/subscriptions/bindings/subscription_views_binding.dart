import 'package:get/get.dart';
import 'package:soccer_sys/modules/subscriptions/bindings/subscription_binding.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_checkout_controller.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainee_plans_controller.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_plan_form_controller.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_plans_controller.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/coaching/services/coaching_service.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_assign_subscription_controller.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_subscribers_controller.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_subscription_edit_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_route_args.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

class TraineePlansBinding extends Bindings {
  @override
  void dependencies() {
    SubscriptionBinding().dependencies();
    Get.lazyPut<TraineePlansController>(
      () => TraineePlansController(Get.find<SubscriptionRepository>()),
    );
  }
}

class SubscriptionCheckoutBinding extends Bindings {
  @override
  void dependencies() {
    SubscriptionBinding().dependencies();
    final args = Get.arguments as SubscriptionCheckoutArgs;
    Get.lazyPut<SubscriptionCheckoutController>(
      () => SubscriptionCheckoutController(
        Get.find<SubscriptionRepository>(),
        args.plan,
      ),
    );
  }
}

class TrainerPlansBinding extends Bindings {
  @override
  void dependencies() {
    SubscriptionBinding().dependencies();
    Get.lazyPut<TrainerPlansController>(
      () => TrainerPlansController(Get.find<SubscriptionRepository>()),
    );
  }
}

class TrainerPlanFormBinding extends Bindings {
  @override
  void dependencies() {
    SubscriptionBinding().dependencies();
    final args = Get.arguments as TrainerPlanFormArgs? ?? const TrainerPlanFormArgs();
    Get.lazyPut<TrainerPlanFormController>(
      () => TrainerPlanFormController(
        Get.find<SubscriptionRepository>(),
        args,
      ),
    );
  }
}

class TrainerSubscribersBinding extends Bindings {
  @override
  void dependencies() {
    SubscriptionBinding().dependencies();
    Get.lazyPut<TrainerSubscribersController>(
      () => TrainerSubscribersController(Get.find<SubscriptionRepository>()),
    );
  }
}

class TrainerSubscriptionEditBinding extends Bindings {
  @override
  void dependencies() {
    SubscriptionBinding().dependencies();
    final args = Get.arguments as TrainerSubscriptionEditArgs;
    Get.lazyPut<TrainerSubscriptionEditController>(
      () => TrainerSubscriptionEditController(
        Get.find<SubscriptionRepository>(),
        args,
      ),
    );
  }
}

class TrainerAssignSubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    SubscriptionBinding().dependencies();
    if (!Get.isRegistered<CoachingService>()) {
      Get.lazyPut<CoachingService>(
        () => CoachingService(Get.find<SupabaseService>()),
        fenix: true,
      );
    }
    Get.lazyPut<TrainerAssignSubscriptionController>(
      () => TrainerAssignSubscriptionController(
        Get.find<SubscriptionRepository>(),
        Get.find<CoachingService>(),
      ),
    );
  }
}
