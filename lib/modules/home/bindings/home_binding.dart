import 'package:get/get.dart';



import 'package:soccer_sys/core/services/presence_service.dart';



import 'package:soccer_sys/modules/activity/bindings/activity_binding.dart';



import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';



import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';



import 'package:soccer_sys/modules/coaching/bindings/coaching_binding.dart';

import 'package:soccer_sys/modules/chat/bindings/chat_binding.dart';



import 'package:soccer_sys/modules/chat/services/chat_service.dart';



import 'package:soccer_sys/modules/home/controllers/home_controller.dart';



import 'package:soccer_sys/modules/profile/bindings/profile_binding.dart';

import 'package:soccer_sys/modules/subscriptions/bindings/subscription_binding.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';
import 'package:soccer_sys/modules/workouts/bindings/workout_binding.dart';



class HomeBinding extends Bindings {

  @override

  void dependencies() {

    AuthBinding().dependencies();



    ChatBinding().dependencies();

    CoachingBinding().dependencies();

    TrainerClientsBinding().dependencies();



    ActivityBinding().dependencies();

    WorkoutBinding().dependencies();



    ProfileBinding().dependencies();

    SubscriptionBinding().dependencies();

    if (!Get.isRegistered<PresenceService>()) {

      Get.put<PresenceService>(

        PresenceService(Get.find<ChatService>()),

        permanent: true,

      );

    }



    if (!Get.isRegistered<HomeController>()) {

      Get.put<HomeController>(HomeController(), permanent: true);

    }



    Future.microtask(() async {
      await Get.find<AuthController>().loadCurrentProfile();
      if (Get.isRegistered<SubscriptionAccessController>()) {
        await Get.find<SubscriptionAccessController>().refresh();
      }
    });

    Get.find<HomeController>().resetTab();

  }

}


