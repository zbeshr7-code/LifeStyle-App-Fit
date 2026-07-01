import 'dart:typed_data';

import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutStorageService {
  WorkoutStorageService(this._supabaseService);

  final SupabaseService _supabaseService;

  static const bucket = 'workout-media';
  static const signedUrlExpiry = 60 * 60 * 24 * 7;

  SupabaseClient get _client => _supabaseService.client;

  Future<String> uploadPhoto({
    required String traineeId,
    required String exerciseId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final path = '$traineeId/$exerciseId.$ext';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeForExtension(ext),
          ),
        );
    return path;
  }

  static String _contentTypeForExtension(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  Future<String> resolveUrl(String storagePath) async {
    if (storagePath.startsWith('http')) return storagePath;
    return _client.storage
        .from(bucket)
        .createSignedUrl(storagePath, signedUrlExpiry);
  }

  Future<void> deletePath(String? path) async {
    if (path == null || path.isEmpty) return;
    await _client.storage.from(bucket).remove([path]);
  }
}
