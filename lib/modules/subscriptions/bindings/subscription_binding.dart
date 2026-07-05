import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';
import 'package:soccer_sys/modules/subscriptions/services/iap_service.dart';
import 'package:soccer_sys/modules/subscriptions/services/subscription_service.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SubscriptionService>()) {
      Get.lazyPut<SubscriptionService>(
        () => SubscriptionService(Get.find<SupabaseService>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<SubscriptionRepository>()) {
      Get.lazyPut<SubscriptionRepository>(
        () => SubscriptionRepository(Get.find<SubscriptionService>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<IapService>()) {
      Get.lazyPut<IapService>(() => IapService(), fenix: true);
    }
    if (!Get.isRegistered<SubscriptionAccessController>()) {
      Get.put<SubscriptionAccessController>(
        SubscriptionAccessController(
          Get.find<SubscriptionRepository>(),
        ),
        permanent: true,
      );
    }
  }
}
