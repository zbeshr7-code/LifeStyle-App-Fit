import 'package:soccer_sys/core/services/supabase_service.dart';

class ProgressService {
  ProgressService(this._supabaseService);

  final SupabaseService _supabaseService;

  String? get _userId => _supabaseService.client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchEntries() async {
    final result = await _supabaseService.client
        .from('trainee_progress_entries')
        .select('*, trainee_progress_photos(*)')
        .order('recorded_at', ascending: false);
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>> createEntry({
    required DateTime recordedAt,
    double? weightKg,
    String? note,
  }) async {
    final userId = _userId!;
    final result = await _supabaseService.client
        .from('trainee_progress_entries')
        .insert({
          'user_id': userId,
          'recorded_at': _dateOnly(recordedAt),
          'weight_kg': weightKg,
          'note': note,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> insertPhoto({
    required String entryId,
    required String storagePath,
    required int sortOrder,
  }) async {
    final userId = _userId!;
    final result = await _supabaseService.client
        .from('trainee_progress_photos')
        .insert({
          'entry_id': entryId,
          'user_id': userId,
          'storage_path': storagePath,
          'sort_order': sortOrder,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<void> deleteEntry(String entryId) async {
    await _supabaseService.client
        .from('trainee_progress_entries')
        .delete()
        .eq('id', entryId);
  }

  String _dateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
