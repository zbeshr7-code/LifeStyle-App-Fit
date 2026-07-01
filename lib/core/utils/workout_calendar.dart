import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';

abstract final class WorkoutCalendar {
  /// Week starts Saturday: 0 = Sat, 1 = Sun, … 6 = Fri.
  static int dayOfWeekFor(DateTime date) => (date.weekday + 1) % 7;

  static int get todayDayOfWeek => dayOfWeekFor(DateTime.now());

  static WorkoutScheduleDayModel? scheduleDayForToday(
    WorkoutProgramModel? program,
  ) {
    if (program == null) return null;
    final today = todayDayOfWeek;
    for (final day in program.orderedDays) {
      if (day.dayOfWeek == today) return day;
    }
    return null;
  }
}
