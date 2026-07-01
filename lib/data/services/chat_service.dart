import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'supabase_service.dart';
import '../../core/utils/error_handler.dart';

class ChatService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  // Access the chat core instance
  SupabaseChatCore get chatCore => SupabaseChatCore.instance;

  Stream<List<types.Message>> getMessagesStream(types.Room room) {
    try {
      // return chatCore.messages(room);
      return List.empty() as Stream<List<types.Message>>;// Placeholder until chat core supports message streaming
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<types.Room> createOrGetRoom(String otherUserId) async {
    try {
      // Find the user first to ensure they exist in Supabase Auth/Profiles
      // The chat core expects the user to be in its 'users' table
      return await chatCore.createRoom(types.User(id: otherUserId));
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<void> sendMessage(types.PartialText message, String roomId) async {
    try {
      chatCore.sendMessage(message, roomId);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<void> sendImageMessage(types.PartialImage message, String roomId) async {
    try {
      chatCore.sendMessage(message, roomId);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<void> sendAudioMessage(types.PartialAudio message, String roomId) async {
    try {
      chatCore.sendMessage(message, roomId);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<String?> getTrainerId(String traineeId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('trainer_id')
          .eq('id', traineeId)
          .maybeSingle();
      return response?['trainer_id'];
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<String> uploadMedia(String filePath, String type) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${filePath.split('.').last}';
      final path = '$type/$fileName';

      await _client.storage.from('chat_media').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      return _client.storage.from('chat_media').getPublicUrl(path);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
