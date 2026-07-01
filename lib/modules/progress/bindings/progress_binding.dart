import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/progress/controllers/progress_entry_controller.dart';
import 'package:soccer_sys/modules/progress/controllers/progress_gallery_controller.dart';
import 'package:soccer_sys/modules/progress/repositories/progress_repository.dart';
import 'package:soccer_sys/modules/progress/services/progress_service.dart';
import 'package:soccer_sys/modules/progress/services/progress_storage_service.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';

class ProgressBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    Get.lazyPut<ProgressService>(
      () => ProgressService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<ProgressStorageService>(
      () => ProgressStorageService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<ProgressRepository>(
      () => ProgressRepository(
        Get.find<ProgressService>(),
        Get.find<ProgressStorageService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<ProgressGalleryController>(
      () => ProgressGalleryController(Get.find<ProgressRepository>()),
    );
  }
}

class ProgressAddEntryBinding extends Bindings {
  @override
  void dependencies() {
    ProgressBinding().dependencies();
    Get.lazyPut<ProgressEntryController>(
      () => ProgressEntryController(
        Get.find<ProgressRepository>(),
        Get.find<AuthController>(),
      ),
    );
  }
}

class ProgressEntryDetailBinding extends Bindings {
  @override
  void dependencies() {
    ProgressBinding().dependencies();
  }
}
