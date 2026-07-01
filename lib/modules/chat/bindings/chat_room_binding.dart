import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/calls/bindings/call_binding.dart';
import 'package:soccer_sys/modules/calls/controllers/call_controller.dart';
import 'package:soccer_sys/modules/chat/bindings/chat_binding.dart';
import 'package:soccer_sys/modules/chat/controllers/chat_room_controller.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/chat/repositories/chat_repository.dart';

class ChatRoomBinding extends Bindings {
  @override
  void dependencies() {
    ChatBinding().dependencies();
    final args = Get.arguments as ChatRoomArgs;
    CallBinding(roomArgs: args).dependencies();
    Get.lazyPut<ChatRoomController>(
      () => ChatRoomController(
        Get.find<ChatRepository>(),
        Get.find<SupabaseService>(),
        args,
      ),
      fenix: true,
    );
  }
}
