import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';

void main() {
  test('NutritionMealModel parses food item lines', () {
    final meal = NutritionMealModel.fromJson({
      'id': 'm1',
      'trainee_id': 't1',
      'trainer_id': 'tr1',
      'day_type': 'workout',
      'title': 'Breakfast',
      'food_items': '4 eggs\n100g oats\nbanana',
      'calories': 650,
      'sort_order': 0,
      'created_at': '2026-06-04T10:00:00Z',
      'updated_at': '2026-06-04T10:00:00Z',
    });

    expect(meal.dayType, NutritionDayType.workout);
    expect(meal.foodItemLines, ['4 eggs', '100g oats', 'banana']);
    expect(meal.calories, 650);
  });
}
