import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/calls/controllers/call_controller.dart';
import 'package:soccer_sys/modules/calls/repositories/call_repository.dart';
import 'package:soccer_sys/modules/calls/services/agora_call_service.dart';
import 'package:soccer_sys/modules/calls/services/call_ringtone_service.dart';
import 'package:soccer_sys/modules/calls/services/call_signaling_service.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';

class CallBinding extends Bindings {
  CallBinding({required this.roomArgs});

  final ChatRoomArgs roomArgs;

  @override
  void dependencies() {
    AuthBinding().dependencies();
    if (!Get.isRegistered<CallSignalingService>()) {
      Get.lazyPut<CallSignalingService>(
        () => CallSignalingService(Get.find<SupabaseService>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<AgoraCallService>()) {
      Get.lazyPut<AgoraCallService>(() => AgoraCallService(), fenix: true);
    }
    if (!Get.isRegistered<CallRingtoneService>()) {
      Get.lazyPut<CallRingtoneService>(() => CallRingtoneService(), fenix: true);
    }
    if (!Get.isRegistered<CallRepository>()) {
      Get.lazyPut<CallRepository>(
        () => CallRepository(
          Get.find<SupabaseService>(),
          Get.find<CallSignalingService>(),
        ),
        fenix: true,
      );
    }
    if (Get.isRegistered<CallController>()) {
      Get.delete<CallController>(force: true);
    }
    Get.put<CallController>(
        CallController(
          Get.find<CallRepository>(),
          Get.find<AgoraCallService>(),
          Get.find<CallRingtoneService>(),
          Get.find<AuthController>(),
          roomArgs,
        ),
    );
  }
}
