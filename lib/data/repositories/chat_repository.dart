import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../services/chat_service.dart';
import 'package:get/get.dart';

class ChatRepository {
  final ChatService _service = Get.find<ChatService>();

  Stream<List<types.Message>> getMessagesStream(types.Room room) {
    return _service.getMessagesStream(room);
  }

  Future<types.Room> createOrGetRoom(String otherUserId) async {
    return await _service.createOrGetRoom(otherUserId);
  }

  Future<void> sendMessage(types.PartialText message, String roomId) async {
    await _service.sendMessage(message, roomId);
  }

  Future<void> sendImageMessage(types.PartialImage message, String roomId) async {
    await _service.sendImageMessage(message, roomId);
  }

  Future<void> sendAudioMessage(types.PartialAudio message, String roomId) async {
    await _service.sendAudioMessage(message, roomId);
  }

  Future<String?> getTrainerId(String traineeId) async {
    return await _service.getTrainerId(traineeId);
  }

  Future<String> uploadMedia(String filePath, String type) async {
    return await _service.uploadMedia(filePath, type);
  }
}
