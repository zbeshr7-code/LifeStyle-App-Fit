import 'dart:typed_data';

import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarStorageService {
  AvatarStorageService(this._supabaseService);

  final SupabaseService _supabaseService;

  static const bucket = 'avatars';

  SupabaseClient get _client => _supabaseService.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final path = '$userId/avatar.$ext';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  String resolveAvatarUrl(String? urlOrPath) {
    if (urlOrPath == null || urlOrPath.isEmpty) return '';
    if (urlOrPath.startsWith('http')) return urlOrPath;
    return _client.storage.from(bucket).getPublicUrl(urlOrPath);
  }
}
