import 'dart:typed_data';

import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressStorageService {
  ProgressStorageService(this._supabaseService);

  final SupabaseService _supabaseService;

  static const bucket = 'progress-photos';
  static const signedUrlExpiry = 60 * 60 * 24 * 7;

  SupabaseClient get _client => _supabaseService.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<String> uploadPhoto({
    required String entryId,
    required String photoId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final path = '$userId/$entryId/$photoId.$ext';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  Future<String> resolveUrl(String storagePath) async {
    if (storagePath.startsWith('http')) return storagePath;
    return _client.storage
        .from(bucket)
        .createSignedUrl(storagePath, signedUrlExpiry);
  }

  Future<void> deletePaths(List<String> paths) async {
    if (paths.isEmpty) return;
    await _client.storage.from(bucket).remove(paths);
  }
}
