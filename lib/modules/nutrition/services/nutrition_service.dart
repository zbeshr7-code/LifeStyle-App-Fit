import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';

class NutritionService {
  NutritionService(this._supabaseService);

  final SupabaseService _supabaseService;

  String? get _userId => _supabaseService.client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchMeals({
    required String traineeId,
    required NutritionDayType dayType,
  }) async {
    final result = await _supabaseService.client
        .from('nutrition_meals')
        .select()
        .eq('trainee_id', traineeId)
        .eq('day_type', dayType.value)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>> createMeal(Map<String, dynamic> payload) async {
    final result = await _supabaseService.client
        .from('nutrition_meals')
        .insert(payload)
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> updateMeal(
    String mealId,
    Map<String, dynamic> payload,
  ) async {
    final result = await _supabaseService.client
        .from('nutrition_meals')
        .update(payload)
        .eq('id', mealId)
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<void> deleteMeal(String mealId) async {
    await _supabaseService.client
        .from('nutrition_meals')
        .delete()
        .eq('id', mealId);
  }

  Future<void> reorderMeals({
    required String traineeId,
    required NutritionDayType dayType,
    required List<String> mealIds,
  }) async {
    await _supabaseService.client.rpc(
      'reorder_nutrition_meals',
      params: {
        'p_trainee_id': traineeId,
        'p_day_type': dayType.value,
        'p_meal_ids': mealIds,
      },
    );
  }

  Future<int> nextSortOrder({
    required String traineeId,
    required NutritionDayType dayType,
  }) async {
    final result = await _supabaseService.client
        .from('nutrition_meals')
        .select('sort_order')
        .eq('trainee_id', traineeId)
        .eq('day_type', dayType.value)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    if (result == null) return 0;
    return ((result['sort_order'] as num?)?.toInt() ?? 0) + 1;
  }

  String? get currentUserId => _userId;
}
