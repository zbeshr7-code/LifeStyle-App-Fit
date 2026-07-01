import 'package:soccer_sys/core/services/supabase_service.dart';

class ActivityService {
  ActivityService(this._supabaseService);

  final SupabaseService _supabaseService;

  Future<Map<String, dynamic>> upsertDailyActivity({
    required String date,
    required int steps,
    required double calories,
    required double distanceKm,
    required int goalSteps,
  }) async {
    final result = await _supabaseService.client.rpc(
      'upsert_daily_activity',
      params: {
        'p_date': date,
        'p_steps': steps,
        'p_calories': calories,
        'p_distance_km': distanceKm,
        'p_goal_steps': goalSteps,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> getActivitySummary({
    required String fromDate,
    required String toDate,
  }) async {
    final result = await _supabaseService.client.rpc(
      'get_activity_summary',
      params: {
        'p_from_date': fromDate,
        'p_to_date': toDate,
      },
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<List<Map<String, dynamic>>> getActivityHistory({
    required int limit,
    required int offset,
  }) async {
    final result = await _supabaseService.client
        .from('daily_activity')
        .select()
        .order('activity_date', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<List<Map<String, dynamic>>> getTraineeActivitySummary({
    required String traineeId,
    required String fromDate,
    required String toDate,
  }) async {
    final result = await _supabaseService.client.rpc(
      'get_trainee_activity_summary',
      params: {
        'p_trainee_id': traineeId,
        'p_from_date': fromDate,
        'p_to_date': toDate,
      },
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<List<Map<String, dynamic>>> getTraineeActivityHistory({
    required String traineeId,
    required int limit,
    required int offset,
  }) async {
    final result = await _supabaseService.client.rpc(
      'get_trainee_activity_history',
      params: {
        'p_trainee_id': traineeId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(result as List);
  }
}
