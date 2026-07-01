import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart' as zego_uikit;
import '../../../core/constants/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../../../data/services/supabase_service.dart';
import 'widgets/audio_player_widget.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Obx(() => ZegoSendCallInvitationButton(
                isVideoCall: false,
                resourceID: "call",
                invitees: [
                  zego_uikit.ZegoUIKitUser(
                    id: controller.trainerId.value,
                    name: 'Trainer',
                  ),
                ],
              )
          ),

        ],
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, color: Colors.black),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('chat_trainer'.tr, style: TextStyle(fontSize: 16.sp)),
                Obx(() => Text(
                  controller.hasTrainer.value ? 'online'.tr : 'searching_trainer'.tr,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: controller.hasTrainer.value ? Colors.green : Colors.orange
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: Obx(() => _buildMessagesList())),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final currentUserId = Get.find<SupabaseService>().currentUser?.id;

    if (!controller.hasTrainer.value) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 80.sp, color: Colors.grey.withOpacity(0.5)),
              SizedBox(height: 16.h),
              Text(
                'no_trainer_assigned'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.messages.isEmpty) {
      return Center(
        child: Text('no_messages'.tr, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.all(20.w),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final message = controller.messages[index];
        final isMe = message.author.id == currentUserId;
        return _buildChatBubble(context, message, isMe);
      },
    );
  }

  Widget _buildChatBubble(BuildContext context, types.Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: message is types.ImageMessage ? EdgeInsets.all(4.r) : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: isMe ? Radius.circular(20.r) : Radius.zero,
            bottomRight: isMe ? Radius.zero : Radius.circular(20.r),
          ),
        ),
        child: _buildMessageContent(message, isMe),
      ),
    );
  }

  Widget _buildMessageContent(types.Message message, bool isMe) {
    if (message is types.TextMessage) {
      return Text(
        message.text,
        style: TextStyle(color: isMe ? Colors.black : null, fontSize: 15.sp),
      );
    } else if (message is types.ImageMessage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.network(message.uri, fit: BoxFit.cover),
      );
    } else if (message is types.AudioMessage) {
      return AudioPlayerWidget(
        url: message.uri,
        isMe: isMe,
        duration: message.duration?.inSeconds,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInputSection() {
    return Obx(() {
      if (controller.isRecording.value) {
        return _buildRecordingUI();
      }
      return _buildNormalInputUI();
    });
  }

  Widget _buildNormalInputUI() {
    return Container(
      padding: EdgeInsets.only(left: 10.w, right: 10.w, bottom: 30.h, top: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            onPressed: controller.hasTrainer.value ? controller.pickAndSendImage : null,
          ),
          Expanded(
            child: TextField(
              controller: controller.messageController,
              enabled: controller.hasTrainer.value,
              onChanged: (text) {
                controller.update();
              },
              decoration: InputDecoration(
                hintText: controller.hasTrainer.value ? 'type_message'.tr : 'locked'.tr,
                fillColor: Theme.of(Get.context!).cardColor,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () {
               if (controller.messageController.text.isNotEmpty) {
                 controller.sendTextMessage();
               }
            },
            onLongPress: controller.hasTrainer.value && controller.messageController.text.isEmpty ? controller.startRecording : null,
            onLongPressEnd: (_) {
               if (controller.isRecording.value) {
                 controller.stopRecording(send: true);
               }
            },
            child: GetBuilder<ChatController>(
              builder: (controller) => CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(
                  controller.messageController.text.isEmpty ? Icons.mic : Icons.send,
                  color: Colors.black
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 30.h, top: 20.h),
      color: Theme.of(Get.context!).cardColor,
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red, size: 24),
          SizedBox(width: 12.w),
          Obx(() {
            final duration = controller.recordingDuration.value;
            final minutes = (duration / 60).floor();
            final seconds = duration % 60;
            return Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          }),
          const Spacer(),
          Text('slide_to_cancel'.tr, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
          SizedBox(width: 20.w),
          GestureDetector(
            onTap: () => controller.stopRecording(send: false),
            child: const Icon(Icons.delete_outline, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
