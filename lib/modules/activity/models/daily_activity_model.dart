class DailyActivityModel {
  const DailyActivityModel({
    required this.id,
    required this.userId,
    required this.activityDate,
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.goalSteps,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime activityDate;
  final int steps;
  final double calories;
  final double distanceKm;
  final int goalSteps;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progressPercent =>
      goalSteps <= 0 ? 0 : (steps / goalSteps * 100).clamp(0, 999);

  bool get goalReached => steps >= goalSteps;

  factory DailyActivityModel.fromJson(Map<String, dynamic> json) {
    return DailyActivityModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityDate: DateTime.parse(json['activity_date'] as String),
      steps: (json['steps'] as num).toInt(),
      calories: _toDouble(json['calories']),
      distanceKm: _toDouble(json['distance_km']),
      goalSteps: (json['goal_steps'] as num).toInt(),
      source: json['source'] as String? ?? 'pedometer',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  DailyActivityModel copyWith({
    int? steps,
    double? calories,
    double? distanceKm,
    int? goalSteps,
  }) {
    return DailyActivityModel(
      id: id,
      userId: userId,
      activityDate: activityDate,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      distanceKm: distanceKm ?? this.distanceKm,
      goalSteps: goalSteps ?? this.goalSteps,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class ActivityDayArgs {
  const ActivityDayArgs({
    required this.date,
    this.activity,
    this.traineeContext,
  });

  final DateTime date;
  final DailyActivityModel? activity;
  final TraineeActivityContext? traineeContext;
}

class TraineeActivityContext {
  const TraineeActivityContext({
    required this.traineeId,
    required this.stepGoal,
    this.heightCm,
    this.weightKg,
  });

  final String traineeId;
  final int stepGoal;
  final double? heightCm;
  final double? weightKg;
}

class TraineeActivityHistoryArgs {
  const TraineeActivityHistoryArgs({required this.traineeContext});

  final TraineeActivityContext traineeContext;
}

enum StepGoalStatus { reached, onTrack, behind, noData }

abstract final class ActivityMetricsCalculator {
  static const defaultStrideM = 0.78;
  static const defaultWeightKg = 70.0;

  static double strideMeters({double? heightCm}) {
    if (heightCm == null || heightCm <= 0) return defaultStrideM;
    return heightCm * 0.415 / 100;
  }

  static double distanceKm(int steps, {double? heightCm}) {
    return steps * strideMeters(heightCm: heightCm) / 1000;
  }

  static double calories(int steps, {double? weightKg}) {
    final weight = (weightKg == null || weightKg <= 0)
        ? defaultWeightKg
        : weightKg;
    return steps * 0.04 * (weight / defaultWeightKg);
  }

  static StepGoalStatus statusFor({
    required int steps,
    required int goal,
    required bool isToday,
  }) {
    if (goal <= 0) return StepGoalStatus.noData;
    if (steps >= goal) return StepGoalStatus.reached;

    if (!isToday) {
      return steps >= goal * 0.7 ? StepGoalStatus.onTrack : StepGoalStatus.behind;
    }

    final hour = DateTime.now().hour;
    final expected = (goal * (hour / 24)).round();
    if (steps >= expected) return StepGoalStatus.onTrack;
    return StepGoalStatus.behind;
  }
}
