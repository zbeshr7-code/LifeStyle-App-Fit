import 'package:get/get.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/repositories/profile_repository.dart';
import 'package:soccer_sys/modules/coaching/bindings/coaching_binding.dart';
import 'package:soccer_sys/modules/coaching/repositories/coaching_repository.dart';
import 'package:soccer_sys/modules/profile/controllers/profile_controller.dart';
import 'package:soccer_sys/modules/profile/controllers/profile_edit_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    CoachingBinding().dependencies();
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        Get.find<AuthController>(),
        Get.find<ProfileRepository>(),
        Get.find<CoachingRepository>(),
      ),
    );
  }
}

class ProfileEditBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    Get.lazyPut<ProfileEditController>(
      () => ProfileEditController(
        Get.find<AuthController>(),
        Get.find<ProfileRepository>(),
      ),
    );
  }
}
