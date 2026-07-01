import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/utils/activity_streak_calculator.dart';

DailyActivityModel _day(DateTime date, int steps, {int goal = 10000}) {
  return DailyActivityModel(
    id: 'id',
    userId: 'user',
    activityDate: date,
    steps: steps,
    calories: 0,
    distanceKm: 0,
    goalSteps: goal,
    source: 'test',
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('ActivityStreakCalculator', () {
    test('counts consecutive goal days including today', () {
      final today = DateTime(2026, 6, 4);
      final activities = [
        _day(DateTime(2026, 6, 1), 12000),
        _day(DateTime(2026, 6, 2), 11000),
        _day(DateTime(2026, 6, 3), 10000),
      ];

      final stats = ActivityStreakCalculator.calculate(
        activities: activities,
        todaySteps: 15000,
        todayGoal: 10000,
        today: today,
      );

      expect(stats.currentStreak, 4);
      expect(stats.includesToday, isTrue);
      expect(stats.streakStartDate, DateTime(2026, 6, 1));
      expect(stats.streakAverageSteps, 12000);
      expect(stats.hasTenDayBadge, isFalse);
    });

    test('stops streak when a day missed goal', () {
      final today = DateTime(2026, 6, 4);
      final activities = [
        _day(DateTime(2026, 6, 1), 5000),
        _day(DateTime(2026, 6, 2), 12000),
        _day(DateTime(2026, 6, 3), 11000),
      ];

      final stats = ActivityStreakCalculator.calculate(
        activities: activities,
        todaySteps: 15000,
        todayGoal: 10000,
        today: today,
      );

      expect(stats.currentStreak, 3);
      expect(stats.streakStartDate, DateTime(2026, 6, 2));
    });

    test('uses yesterday when today goal not reached yet', () {
      final today = DateTime(2026, 6, 4);
      final activities = [
        _day(DateTime(2026, 6, 2), 12000),
        _day(DateTime(2026, 6, 3), 11000),
      ];

      final stats = ActivityStreakCalculator.calculate(
        activities: activities,
        todaySteps: 3000,
        todayGoal: 10000,
        today: today,
      );

      expect(stats.currentStreak, 2);
      expect(stats.includesToday, isFalse);
    });
  });
}
