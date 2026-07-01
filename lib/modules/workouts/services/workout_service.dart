import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';

class WorkoutService {
  WorkoutService(this._supabaseService);

  final SupabaseService _supabaseService;

  String? get _userId => _supabaseService.client.auth.currentUser?.id;

  Future<Map<String, dynamic>> ensureProgram(String traineeId) async {
    final result = await _supabaseService.client.rpc(
      'ensure_workout_program',
      params: {'p_trainee_id': traineeId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> fetchProgram(String traineeId) async {
    final result = await _supabaseService.client
        .from('workout_programs')
        .select('*, workout_schedule_days(*)')
        .eq('trainee_id', traineeId)
        .maybeSingle();
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> updateProgramName(
    String programId,
    String name,
  ) async {
    final result = await _supabaseService.client
        .from('workout_programs')
        .update({'name': name})
        .eq('id', programId)
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> updateScheduleDay({
    required String dayId,
    required WorkoutDayType dayType,
    required String label,
  }) async {
    final result = await _supabaseService.client
        .from('workout_schedule_days')
        .update({
          'day_type': dayType.value,
          'label': label,
        })
        .eq('id', dayId)
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> fetchExercises(String scheduleDayId) async {
    final result = await _supabaseService.client
        .from('workout_exercises')
        .select()
        .eq('schedule_day_id', scheduleDayId)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> payload) async {
    final result = await _supabaseService.client
        .from('workout_exercises')
        .insert(payload)
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> updateExercise(
    String exerciseId,
    Map<String, dynamic> payload,
  ) async {
    final result = await _supabaseService.client
        .from('workout_exercises')
        .update(payload)
        .eq('id', exerciseId)
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _supabaseService.client
        .from('workout_exercises')
        .delete()
        .eq('id', exerciseId);
  }

  Future<void> reorderExercises({
    required String scheduleDayId,
    required List<String> exerciseIds,
  }) async {
    await _supabaseService.client.rpc(
      'reorder_workout_exercises',
      params: {
        'p_schedule_day_id': scheduleDayId,
        'p_exercise_ids': exerciseIds,
      },
    );
  }

  Future<int> nextExerciseSortOrder(String scheduleDayId) async {
    final result = await _supabaseService.client
        .from('workout_exercises')
        .select('sort_order')
        .eq('schedule_day_id', scheduleDayId)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    if (result == null) return 0;
    return ((result['sort_order'] as num?)?.toInt() ?? 0) + 1;
  }

  String? get currentUserId => _userId;

  Future<List<Map<String, dynamic>>> fetchWeightTrials({
    required String traineeId,
    DateTime? fromDate,
  }) async {
    var query = _supabaseService.client
        .from('workout_weight_trials')
        .select('*, workout_schedule_days(*)')
        .eq('trainee_id', traineeId);

    if (fromDate != null) {
      query = query.gte(
        'trial_date',
        WorkoutDateUtils.dateOnly(fromDate),
      );
    }

    final result = await query.order('trial_date', ascending: true);
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>?> fetchWeightTrialForDate({
    required String traineeId,
    required DateTime date,
  }) async {
    final result = await _supabaseService.client
        .from('workout_weight_trials')
        .select('*, workout_schedule_days(*)')
        .eq('trainee_id', traineeId)
        .eq('trial_date', WorkoutDateUtils.dateOnly(date))
        .maybeSingle();
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> createWeightTrial(
    Map<String, dynamic> payload,
  ) async {
    final result = await _supabaseService.client
        .from('workout_weight_trials')
        .insert(payload)
        .select('*, workout_schedule_days(*)')
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<void> deleteWeightTrial(String trialId) async {
    await _supabaseService.client
        .from('workout_weight_trials')
        .delete()
        .eq('id', trialId);
  }
}
