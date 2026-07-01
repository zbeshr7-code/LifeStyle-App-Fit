import 'dart:typed_data';

import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionStorageService {
  NutritionStorageService(this._supabaseService);

  final SupabaseService _supabaseService;

  static const bucket = 'meal-photos';
  static const signedUrlExpiry = 60 * 60 * 24 * 7;

  SupabaseClient get _client => _supabaseService.client;

  Future<String> uploadPhoto({
    required String traineeId,
    required String mealId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final path = '$traineeId/$mealId.$ext';

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

  Future<void> deletePath(String? path) async {
    if (path == null || path.isEmpty) return;
    await _client.storage.from(bucket).remove([path]);
  }
}
