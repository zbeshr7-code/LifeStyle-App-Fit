import 'dart:io';
import 'dart:typed_data';

import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatStorageService {
  ChatStorageService(this._supabaseService);

  final SupabaseService _supabaseService;

  static const bucket = 'chat-media';
  static const signedUrlExpiry = 60 * 60 * 24 * 7;

  SupabaseClient get _client => _supabaseService.client;

  Future<String> uploadFile({
    required String roomId,
    required String messageId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$roomId/$messageId/$fileName';
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  Future<String> uploadFromPath({
    required String roomId,
    required String messageId,
    required String filePath,
    required String fileName,
  }) async {
    final file = File(filePath);
    return uploadFile(
      roomId: roomId,
      messageId: messageId,
      fileName: fileName,
      bytes: await file.readAsBytes(),
    );
  }

  Future<String> resolveUrl(String storagePath) async {
    if (storagePath.startsWith('http')) return storagePath;
    return _client.storage
        .from(bucket)
        .createSignedUrl(storagePath, signedUrlExpiry);
  }
}
