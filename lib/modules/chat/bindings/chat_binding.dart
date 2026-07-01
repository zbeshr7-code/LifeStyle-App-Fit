import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/chat/controllers/chat_controller.dart';
import 'package:soccer_sys/modules/chat/repositories/chat_repository.dart';
import 'package:soccer_sys/modules/chat/services/chat_service.dart';
import 'package:soccer_sys/modules/chat/services/chat_storage_service.dart';
import 'package:soccer_sys/modules/coaching/bindings/coaching_binding.dart';
import 'package:soccer_sys/modules/coaching/repositories/coaching_repository.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    CoachingBinding().dependencies();
    Get.lazyPut<ChatService>(
      () => ChatService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<ChatStorageService>(
      () => ChatStorageService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<ChatRepository>(
      () => ChatRepository(
        Get.find<ChatService>(),
        Get.find<ChatStorageService>(),
        Get.find<CoachingRepository>(),
      ),
      fenix: true,
    );
    if (!Get.isRegistered<ChatController>()) {
      Get.put<ChatController>(
        ChatController(
          Get.find<ChatRepository>(),
          Get.find<AuthController>(),
        ),
        permanent: true,
      );
    }
  }
}
