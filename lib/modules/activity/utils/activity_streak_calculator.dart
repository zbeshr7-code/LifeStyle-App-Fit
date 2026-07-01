import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';

class ActivityStreakStats {
  const ActivityStreakStats({
    required this.currentStreak,
    this.streakStartDate,
    required this.streakAverageSteps,
    required this.last7DaysAverage,
    required this.last30DaysAverage,
    required this.includesToday,
    required this.milestoneLevel,
  });

  final int currentStreak;
  final DateTime? streakStartDate;
  final int streakAverageSteps;
  final int last7DaysAverage;
  final int last30DaysAverage;
  final bool includesToday;
  final int milestoneLevel;

  bool get hasStreak => currentStreak > 0;

  bool get hasTenDayBadge => currentStreak >= 10;

  bool get hasWeekBadge => currentStreak >= 7;

  String get motivationalKey =>
      ActivityStreakCalculator.motivationalKeyFor(currentStreak);

  static const empty = ActivityStreakStats(
    currentStreak: 0,
    streakAverageSteps: 0,
    last7DaysAverage: 0,
    last30DaysAverage: 0,
    includesToday: false,
    milestoneLevel: 0,
  );
}

abstract final class ActivityStreakCalculator {
  static ActivityStreakStats calculate({
    required List<DailyActivityModel> activities,
    required int todaySteps,
    required int todayGoal,
    required DateTime today,
  }) {
    final todayDate = _dateOnly(today);
    final byDate = <DateTime, DailyActivityModel>{
      for (final activity in activities)
        _dateOnly(activity.activityDate): activity,
    };

    final todayReached = todayGoal > 0 && todaySteps >= todayGoal;
    var cursor = todayReached
        ? todayDate
        : todayDate.subtract(const Duration(days: 1));

    var streak = 0;
    var streakStepsSum = 0;
    DateTime? startDate;

    while (true) {
      final isToday = _dateOnly(cursor) == todayDate;

      if (isToday) {
        if (!todayReached) break;
        streak++;
        streakStepsSum += todaySteps;
        startDate = cursor;
      } else {
        final day = byDate[cursor];
        if (day == null || !day.goalReached) break;
        streak++;
        streakStepsSum += day.steps;
        startDate = cursor;
      }

      cursor = cursor.subtract(const Duration(days: 1));
      if (streak > 366) break;
    }

    final last7Avg = _averageStepsInRange(
      byDate: byDate,
      today: todayDate,
      todaySteps: todaySteps,
      days: 7,
    );
    final last30Avg = _averageStepsInRange(
      byDate: byDate,
      today: todayDate,
      todaySteps: todaySteps,
      days: 30,
    );

    return ActivityStreakStats(
      currentStreak: streak,
      streakStartDate: startDate,
      streakAverageSteps:
          streak > 0 ? (streakStepsSum / streak).round() : 0,
      last7DaysAverage: last7Avg,
      last30DaysAverage: last30Avg,
      includesToday: todayReached && streak > 0,
      milestoneLevel: _milestoneFor(streak),
    );
  }

  static String motivationalKeyFor(int streak) {
    if (streak >= 30) return 'activity_streak_msg_30';
    if (streak >= 14) return 'activity_streak_msg_14';
    if (streak >= 10) return 'activity_streak_msg_10';
    if (streak >= 7) return 'activity_streak_msg_7';
    if (streak >= 3) return 'activity_streak_msg_3';
    if (streak >= 1) return 'activity_streak_msg_1';
    return 'activity_streak_msg_0';
  }

  static int _milestoneFor(int streak) {
    if (streak >= 30) return 30;
    if (streak >= 14) return 14;
    if (streak >= 10) return 10;
    if (streak >= 7) return 7;
    if (streak >= 3) return 3;
    return streak > 0 ? 1 : 0;
  }

  static int _averageStepsInRange({
    required Map<DateTime, DailyActivityModel> byDate,
    required DateTime today,
    required int todaySteps,
    required int days,
  }) {
    var sum = 0;
    var count = 0;
    for (var i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (_dateOnly(date) == today) {
        sum += todaySteps;
        count++;
        continue;
      }
      final day = byDate[date];
      if (day != null) {
        sum += day.steps;
        count++;
      }
    }
    if (count == 0) return 0;
    return (sum / count).round();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
