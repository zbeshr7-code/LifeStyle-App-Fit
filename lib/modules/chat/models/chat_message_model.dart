import 'package:soccer_sys/modules/chat/models/message_type.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.audioDurationMs,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final MessageType type;
  final String? content;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final int? audioDurationMs;
  final DateTime createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      type: MessageType.fromString(json['type'] as String),
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      audioDurationMs: (json['audio_duration_ms'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'room_id': roomId,
      'sender_id': senderId,
      'type': type.value,
      if (content != null) 'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (audioDurationMs != null) 'audio_duration_ms': audioDurationMs,
    };
  }
}
