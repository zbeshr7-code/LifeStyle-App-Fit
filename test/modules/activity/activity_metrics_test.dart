import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';

void main() {
  group('ActivityMetricsCalculator', () {
    test('computes distance from height', () {
      final km = ActivityMetricsCalculator.distanceKm(10000, heightCm: 175);
      expect(km, closeTo(7.2625, 0.01));
    });

    test('computes calories from weight', () {
      final kcal = ActivityMetricsCalculator.calories(5000, weightKg: 70);
      expect(kcal, closeTo(200, 0.01));
    });

    test('status reached when steps meet goal', () {
      expect(
        ActivityMetricsCalculator.statusFor(
          steps: 10000,
          goal: 10000,
          isToday: true,
        ),
        StepGoalStatus.reached,
      );
    });
  });

  group('DailyActivityModel', () {
    test('fromJson maps fields', () {
      final model = DailyActivityModel.fromJson({
        'id': 'id-1',
        'user_id': 'user-1',
        'activity_date': '2026-06-04',
        'steps': 8500,
        'calories': 340,
        'distance_km': 6.5,
        'goal_steps': 10000,
        'source': 'pedometer',
        'created_at': '2026-06-04T10:00:00Z',
        'updated_at': '2026-06-04T10:00:00Z',
      });

      expect(model.steps, 8500);
      expect(model.goalReached, isFalse);
      expect(model.progressPercent, closeTo(85, 0.1));
    });
  });
}
