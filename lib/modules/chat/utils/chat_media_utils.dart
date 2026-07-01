import 'package:soccer_sys/modules/chat/models/message_type.dart';

abstract final class ChatMediaUtils {
  static const _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    '3gp',
    'm4v',
  };

  static bool isVideoFileName(String? fileName) {
    if (fileName == null || fileName.isEmpty) return false;
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return _videoExtensions.contains(ext);
  }

  static bool isVideoMessage(MessageType type, String? fileName) {
    return type == MessageType.video || isVideoFileName(fileName);
  }

  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
