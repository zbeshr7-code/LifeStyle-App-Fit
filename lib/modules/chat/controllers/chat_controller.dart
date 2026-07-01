import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/chat/repositories/chat_repository.dart';
import 'package:soccer_sys/modules/chat/widgets/new_chat_bottom_sheet.dart';

class ChatController extends GetxController {
  ChatController(this._chatRepository, this._authController);

  final ChatRepository _chatRepository;
  final AuthController _authController;

  final rooms = <ChatRoomModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;

  int get totalUnreadCount =>
      rooms.fold(0, (sum, room) => sum + room.unreadCount);

  int get roomsWithUnreadCount =>
      rooms.where((room) => room.hasUnread).length;

  @override
  void onInit() {
    super.onInit();
    fetchRooms();
    _chatRepository.updateLastSeen();
    _chatRepository.subscribeToRoomList(fetchRooms);
  }

  @override
  void onClose() {
    _chatRepository.unsubscribeFromRoomList();
    super.onClose();
  }

  Future<void> fetchRooms() async {
    status.value = RxStatus.loading();
    final result = await _chatRepository.fetchRooms();
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    rooms.assignAll(result.rooms);
    status.value = RxStatus.success();
  }

  void clearRoomUnread(String roomId) {
    final index = rooms.indexWhere((room) => room.roomId == roomId);
    if (index < 0 || rooms[index].unreadCount == 0) return;
    rooms[index] = rooms[index].copyWith(unreadCount: 0);
    rooms.refresh();
  }

  void openNewChatSheet() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    if (user.isTrainee && !user.hasTrainer) {
      Get.snackbar('', 'coaching_select_trainer_first'.tr,
          snackPosition: SnackPosition.BOTTOM);
      Get.toNamed(AppRoutes.chooseTrainer);
      return;
    }

    final targetRole =
        user.isTrainer ? UserRole.trainee : UserRole.trainer;

    Get.bottomSheet(
      NewChatBottomSheet(
        targetRole: targetRole,
        onPeerSelected: startChatWithPeer,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> startChatWithPeer(ChatPeerModel peer, {bool popSheet = true}) async {
    if (popSheet && (Get.isBottomSheetOpen ?? false)) {
      Get.back();
    }
    status.value = RxStatus.loading();

    final result = await _chatRepository.getOrCreateRoom(peer.id);
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }

    status.value = RxStatus.success();
    await fetchRooms();
    openRoom(
      ChatRoomArgs(
        roomId: result.roomId!,
        peerId: peer.id,
        peerName: peer.fullName,
        peerAvatarUrl: peer.avatarUrl,
      ),
    );
  }

  void openRoom(ChatRoomArgs args) {
    clearRoomUnread(args.roomId);
    Get.toNamed(AppRoutes.chatRoom, arguments: args)?.then((_) => fetchRooms());
  }

  void openExistingRoom(ChatRoomModel room) {
    openRoom(
      ChatRoomArgs(
        roomId: room.roomId,
        peerId: room.peerId,
        peerName: room.peerFullName,
        peerAvatarUrl: room.peerAvatarUrl,
      ),
    );
  }
}
