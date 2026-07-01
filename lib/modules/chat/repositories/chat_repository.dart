import 'dart:typed_data';

import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:soccer_sys/modules/chat/models/chat_message_model.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/chat/models/message_type.dart';
import 'package:soccer_sys/modules/chat/services/chat_service.dart';
import 'package:soccer_sys/modules/chat/services/chat_storage_service.dart';
import 'package:soccer_sys/modules/coaching/repositories/coaching_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  ChatRepository(
    this._chatService,
    this._storageService,
    this._coachingRepository,
  );

  final ChatService _chatService;
  final ChatStorageService _storageService;
  final CoachingRepository _coachingRepository;

  RealtimeChannel? _roomListChannel;
  RealtimeChannel? _roomChannel;
  RealtimeChannel? _presenceChannel;

  Future<({Failure? failure, List<ChatRoomModel> rooms})> fetchRooms() async {
    try {
      final data = await _chatService.fetchRooms();
      final rooms = data.map(ChatRoomModel.fromJson).toList();
      return (failure: null, rooms: rooms);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), rooms: <ChatRoomModel>[]);
    }
  }

  Future<({Failure? failure, List<ChatPeerModel> peers})> fetchAssignedPeers({
    required UserRole myRole,
  }) async {
    if (myRole == UserRole.trainer) {
      final result = await _coachingRepository.fetchMyTrainees();
      final peers = result.trainees.map(ChatPeerModel.fromUser).toList();
      return (failure: result.failure, peers: peers);
    }
    final result = await _coachingRepository.fetchMyTrainer();
    if (result.failure != null) {
      return (failure: result.failure, peers: <ChatPeerModel>[]);
    }
    return (
      failure: null,
      peers: result.trainer != null ? [result.trainer!] : <ChatPeerModel>[],
    );
  }

  Future<({Failure? failure, List<ChatPeerModel> peers})> fetchPeersForRole(
    UserRole role,
  ) async {
    try {
      final data = await _chatService.fetchPeersByRole(role.value);
      final peers = data.map(ChatPeerModel.fromJson).toList();
      return (failure: null, peers: peers);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), peers: <ChatPeerModel>[]);
    }
  }

  Future<({Failure? failure, String? roomId})> getOrCreateRoom(
    String peerId,
  ) async {
    try {
      final roomId = await _chatService.getOrCreateDirectRoom(peerId);
      return (failure: null, roomId: roomId);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), roomId: null);
    }
  }

  Future<Failure?> markRoomAsRead(String roomId) async {
    try {
      await _chatService.markRoomAsRead(roomId);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<void> updateLastSeen() async {
    try {
      await _chatService.updateLastSeen();
    } catch (_) {}
  }

  Future<DateTime?> fetchPeerLastReadAt({
    required String roomId,
    required String peerId,
  }) async {
    try {
      return await _chatService.fetchPeerLastReadAt(
        roomId: roomId,
        peerId: peerId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> fetchPeerLastSeen(String peerId) async {
    try {
      return await _chatService.fetchPeerLastSeen(peerId);
    } catch (_) {
      return null;
    }
  }

  Future<({Failure? failure, List<ChatMessageModel> messages})> fetchMessages(
    String roomId,
  ) async {
    try {
      final data = await _chatService.fetchMessages(roomId);
      final messages = data.map(ChatMessageModel.fromJson).toList();
      return (failure: null, messages: messages);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), messages: <ChatMessageModel>[]);
    }
  }

  Future<({Failure? failure, ChatMessageModel? message})> sendTextMessage({
    required String roomId,
    required String content,
  }) async {
    return _sendMessage(
      roomId: roomId,
      type: MessageType.text,
      content: content,
    );
  }

  Future<({Failure? failure, ChatMessageModel? message})> sendCallLogMessage({
    required String roomId,
    required String content,
  }) async {
    return _sendMessage(
      roomId: roomId,
      type: MessageType.call,
      content: content,
    );
  }

  Future<({Failure? failure, ChatMessageModel? message})> sendMediaMessage({
    required String roomId,
    required MessageType type,
    required List<int> bytes,
    required String fileName,
    String? content,
    int? audioDurationMs,
  }) async {
    try {
      final messageId =
          '${DateTime.now().millisecondsSinceEpoch}_${_chatService.currentUserId}';

      final mediaUrl = await _storageService.uploadFile(
        roomId: roomId,
        messageId: messageId,
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );

      return _sendMessage(
        roomId: roomId,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        fileName: fileName,
        fileSize: bytes.length,
        audioDurationMs: audioDurationMs,
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), message: null);
    }
  }

  Future<({Failure? failure, ChatMessageModel? message})> _sendMessage({
    required String roomId,
    required MessageType type,
    String? content,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    int? audioDurationMs,
  }) async {
    try {
      final senderId = _chatService.currentUserId!;
      final data = await _chatService.sendMessage(
        roomId: roomId,
        senderId: senderId,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        fileName: fileName,
        fileSize: fileSize,
        audioDurationMs: audioDurationMs,
      );
      return (
        failure: null,
        message: ChatMessageModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), message: null);
    }
  }

  void subscribeToPeerPresence(
    String peerId,
    void Function(DateTime? lastSeen) onUpdate,
  ) {
    unsubscribeFromPeerPresence();
    _presenceChannel = _chatService.subscribeToPeerPresence(peerId, onUpdate);
  }

  void unsubscribeFromPeerPresence() {
    final channel = _presenceChannel;
    if (channel != null) {
      _chatService.removeChannel(channel);
      _presenceChannel = null;
    }
  }

  void subscribeToRoomList(void Function() onChange) {
    unsubscribeFromRoomList();
    _roomListChannel = _chatService.subscribeToAllMessages(onChange);
  }

  void unsubscribeFromRoomList() {
    final channel = _roomListChannel;
    if (channel != null) {
      _chatService.removeChannel(channel);
      _roomListChannel = null;
    }
  }

  void subscribeToRoom(
    String roomId,
    void Function(ChatMessageModel message) onMessage,
  ) {
    unsubscribeFromRoom();
    _roomChannel = _chatService.subscribeToRoomMessages(roomId, (payload) {
      onMessage(ChatMessageModel.fromJson(payload));
    });
  }

  void unsubscribeFromRoom() {
    final channel = _roomChannel;
    if (channel != null) {
      _chatService.removeChannel(channel);
      _roomChannel = null;
    }
  }
}
