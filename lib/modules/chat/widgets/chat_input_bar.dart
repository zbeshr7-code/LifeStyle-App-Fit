import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/chat/controllers/chat_room_controller.dart';
import 'package:soccer_sys/modules/chat/widgets/chat_audio_waveform.dart';

class ChatInputBar extends GetView<ChatRoomController> {
  const ChatInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          end: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSolid,
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder),
          ),
        ),
        child: controller.isRecording.value
            ? _RecordingBar(controller: controller)
            : Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                    onPressed: controller.showAttachSheet,
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller.textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.sendText(),
                      decoration: InputDecoration(
                        hintText: 'chat_type_message'.tr,
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onLongPressStart: (_) => controller.startRecording(),
                    onLongPressEnd: (_) => controller.stopRecordingAndSend(),
                    onLongPressCancel: controller.cancelRecording,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: controller.toggleRecording,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.mic, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: controller.isSending.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(Icons.send),
                    color: AppColors.primary,
                    onPressed:
                        controller.isSending.value ? null : controller.sendText,
                  ),
                ],
              ),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({required this.controller});

  final ChatRoomController controller;

  String _formatElapsed(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _formatElapsed(controller.recordingElapsed.value),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.error,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ChatAudioWaveform(
              levels: controller.recordingAmplitudes.toList(),
              live: true,
              height: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: controller.cancelRecording,
            child: Text('chat_cancel'.tr),
          ),
          FilledButton(
            onPressed: controller.stopRecordingAndSend,
            child: Text('chat_send'.tr),
          ),
        ],
      ),
    );
  }
}
