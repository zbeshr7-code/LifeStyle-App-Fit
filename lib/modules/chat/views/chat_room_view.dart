import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/calls/controllers/call_controller.dart';
import 'package:soccer_sys/modules/calls/models/call_models.dart';
import 'package:soccer_sys/modules/chat/controllers/chat_room_controller.dart';
import 'package:soccer_sys/modules/chat/utils/chat_presence_utils.dart';
import 'package:soccer_sys/modules/chat/widgets/chat_input_bar.dart';
import 'package:soccer_sys/modules/chat/widgets/chat_message_bubble.dart';

class ChatRoomView extends GetView<ChatRoomController> {
  const ChatRoomView({super.key});

  static bool get _supportsCalls =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(controller.args.peerName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage: controller.args.peerAvatarUrl != null
                      ? NetworkImage(controller.args.peerAvatarUrl!)
                      : null,
                  child: controller.args.peerAvatarUrl == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    controller.args.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Obx(() {
                  final online =
                      ChatPresenceUtils.isOnline(controller.peerLastSeen.value);
                  if (!online) return const SizedBox.shrink();
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsetsDirectional.only(start: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ],
            ),
            Obx(
              () => Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: Text(
                  ChatPresenceUtils.formatStatus(controller.peerLastSeen.value),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ChatPresenceUtils.isOnline(
                                controller.peerLastSeen.value)
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_supportsCalls)
            IconButton(
              tooltip: 'call_audio'.tr,
              icon: Icon(Icons.phone_outlined),
              color: AppColors.primary,
              onPressed: () => Get.find<CallController>().startOutgoingCall(
                CallType.audio,
              ),
            ),
          if (_supportsCalls)
            IconButton(
              tooltip: 'call_video'.tr,
              icon: Icon(Icons.videocam_outlined),
              color: AppColors.primary,
              onPressed: () => Get.find<CallController>().startOutgoingCall(
                CallType.video,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.status.value.isLoading &&
                  controller.messages.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (controller.status.value.isError &&
                  controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.errorMessage.value,
                        style: TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: controller.loadMessages,
                        child: Text('retry'.tr),
                      ),
                    ],
                  ),
                );
              }

              // Rebuild ticks when peer read cursor updates.
              controller.peerLastReadAt.value;

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AppSpacing.md,
                ),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMine =
                      message.senderId == controller.currentUserId;
                  return ChatMessageBubble(
                    message: message,
                    isMine: isMine,
                    isReadByPeer: isMine
                        ? controller.isMessageReadByPeer(message)
                        : false,
                  );
                },
              );
            }),
          ),
          const ChatInputBar(),
        ],
      ),
    );
  }
}
