import 'package:get/get.dart';
import 'package:soccer_sys/modules/calls/models/call_log_payload.dart';
import 'package:soccer_sys/modules/calls/models/call_models.dart';

abstract final class CallLogFormatter {
  static String formatBubble(CallLogPayload payload) {
    final isVideo = payload.callType == CallType.video;
    final duration = _formatDuration(payload.durationSeconds);

    return switch (payload.event) {
      CallLogEvent.ended =>
        isVideo ? 'call_log_ended_video'.trParams({'duration': duration}) : 'call_log_ended_audio'.trParams({'duration': duration}),
      CallLogEvent.missed =>
        isVideo ? 'call_log_missed_video'.tr : 'call_log_missed_audio'.tr,
      CallLogEvent.declined =>
        isVideo ? 'call_log_declined_video'.tr : 'call_log_declined_audio'.tr,
      CallLogEvent.noAnswer =>
        isVideo ? 'call_log_no_answer_video'.tr : 'call_log_no_answer_audio'.tr,
      CallLogEvent.cancelled =>
        isVideo ? 'call_log_cancelled_video'.tr : 'call_log_cancelled_audio'.tr,
    };
  }

  static String formatPreview(CallLogPayload payload) {
    return formatBubble(payload);
  }

  static String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
