import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/chat/models/chat_message_model.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/chat/models/message_type.dart';

import 'package:soccer_sys/modules/chat/models/message_type.dart';
import 'package:soccer_sys/modules/chat/utils/chat_media_utils.dart';

void main() {
  group('ChatRoomModel', () {
    test('fromJson maps room list fields', () {
      final room = ChatRoomModel.fromJson({
        'room_id': 'room-1',
        'peer_id': 'peer-1',
        'peer_first_name': 'Ali',
        'peer_last_name': 'Hassan',
        'peer_avatar_url': null,
        'peer_role': 'trainer',
        'last_message_type': 'text',
        'last_message_content': 'Hello',
        'last_message_at': '2026-06-04T10:00:00Z',
        'unread_count': 2,
      });

      expect(room.roomId, 'room-1');
      expect(room.peerFullName, 'Ali Hassan');
      expect(room.lastMessageType, MessageType.text);
      expect(room.unreadCount, 2);
      expect(room.hasUnread, isTrue);

      final cleared = room.copyWith(unreadCount: 0);
      expect(cleared.hasUnread, isFalse);
      expect(cleared.peerFullName, 'Ali Hassan');
    });
  });

  group('ChatMessageModel', () {
    test('fromJson maps message fields', () {
      final message = ChatMessageModel.fromJson({
        'id': 'msg-1',
        'room_id': 'room-1',
        'sender_id': 'user-1',
        'type': 'image',
        'content': null,
        'media_url': 'room-1/msg-1/photo.jpg',
        'file_name': 'photo.jpg',
        'file_size': 1024,
        'audio_duration_ms': null,
        'created_at': '2026-06-04T10:00:00Z',
      });

      expect(message.type, MessageType.image);
      expect(message.mediaUrl, 'room-1/msg-1/photo.jpg');
      expect(message.fileSize, 1024);
    });
  });

  group('ChatMediaUtils', () {
    test('detects video file extensions', () {
      expect(ChatMediaUtils.isVideoFileName('clip.mp4'), isTrue);
      expect(ChatMediaUtils.isVideoFileName('doc.pdf'), isFalse);
    });

    test('MessageType.video maps from string', () {
      expect(MessageType.fromString('video'), MessageType.video);
    });
  });
}
