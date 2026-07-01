import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/chat/controllers/chat_controller.dart';
import 'package:soccer_sys/modules/chat/widgets/chat_room_tile.dart';

class ChatRoomsView extends GetView<ChatController> {
  const ChatRoomsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Obx(() {
          final unread = controller.totalUnreadCount;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'nav_chats'.tr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (unread > 0)
                Text(
                  'chat_unread_summary'.trParams({'count': '$unread'}),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        onPressed: controller.openNewChatSheet,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.status.value.isLoading && controller.rooms.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.status.value.isError && controller.rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: controller.fetchRooms,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (controller.rooms.isEmpty) {
          return Center(
            child: Text(
              'chat_no_rooms'.tr,
              style:  TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.fetchRooms,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.rooms.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 72,
              color: AppColors.surfaceBorder,
            ),
            itemBuilder: (context, index) {
              final room = controller.rooms[index];
              return ChatRoomTile(
                room: room,
                onTap: () => controller.openExistingRoom(room),
              );
            },
          ),
        );
      }),
    );
  }
}
