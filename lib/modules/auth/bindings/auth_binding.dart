import 'package:get/get.dart';
import 'package:soccer_sys/core/services/fcm_service.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/repositories/auth_repository.dart';
import 'package:soccer_sys/modules/auth/repositories/profile_repository.dart';
import 'package:soccer_sys/modules/auth/services/auth_service.dart';
import 'package:soccer_sys/modules/auth/services/avatar_storage_service.dart';
import 'package:soccer_sys/modules/auth/services/profile_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupabaseService>(() => SupabaseService(), fenix: true);
    Get.lazyPut<FcmService>(
      () => FcmService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<AuthService>(
      () => AuthService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<ProfileService>(
      () => ProfileService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<AvatarStorageService>(
      () => AvatarStorageService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find<AuthService>()),
      fenix: true,
    );
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(
        Get.find<ProfileService>(),
        Get.find<AvatarStorageService>(),
      ),
      fenix: true,
    );
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          Get.find<AuthRepository>(),
          Get.find<ProfileRepository>(),
        ),
        permanent: true,
      );
    }
  }
}
