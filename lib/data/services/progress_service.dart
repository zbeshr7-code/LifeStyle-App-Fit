import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'supabase_service.dart';
import '../../core/utils/error_handler.dart';

class ProgressService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  Future<List<Map<String, dynamic>>> getProgressPhotos(String traineeId) async {
    try {
      final response = await _client
          .from('progress_photos')
          .select()
          .eq('trainee_id', traineeId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<void> addProgressPhoto(Map<String, dynamic> data) async {
    try {
      await _client.from('progress_photos').insert(data);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
