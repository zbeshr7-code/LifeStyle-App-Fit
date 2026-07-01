enum WorkoutDayType {
  workout,
  cardio,
  rest;

  String get value => name;

  static WorkoutDayType fromString(String? value) {
    return WorkoutDayType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => WorkoutDayType.rest,
    );
  }

  bool get hasExercises => this != WorkoutDayType.rest;
}

class WorkoutProgramModel {
  const WorkoutProgramModel({
    required this.id,
    required this.traineeId,
    required this.trainerId,
    required this.name,
    required this.scheduleDays,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String traineeId;
  final String trainerId;
  final String name;
  final List<WorkoutScheduleDayModel> scheduleDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<WorkoutScheduleDayModel> get orderedDays {
    final days = List<WorkoutScheduleDayModel>.from(scheduleDays);
    days.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    return days;
  }

  factory WorkoutProgramModel.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['workout_schedule_days'] as List? ?? [];
    return WorkoutProgramModel(
      id: json['id'] as String,
      traineeId: json['trainee_id'] as String,
      trainerId: json['trainer_id'] as String,
      name: json['name'] as String? ?? '',
      scheduleDays: daysRaw
          .map((d) => WorkoutScheduleDayModel.fromJson(
                Map<String, dynamic>.from(d as Map),
              ))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  WorkoutProgramModel copyWith({
    String? name,
    List<WorkoutScheduleDayModel>? scheduleDays,
  }) {
    return WorkoutProgramModel(
      id: id,
      traineeId: traineeId,
      trainerId: trainerId,
      name: name ?? this.name,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class WorkoutScheduleDayModel {
  const WorkoutScheduleDayModel({
    required this.id,
    required this.programId,
    required this.traineeId,
    required this.dayOfWeek,
    required this.dayType,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String programId;
  final String traineeId;
  final int dayOfWeek;
  final WorkoutDayType dayType;
  final String label;
  final DateTime createdAt;
  final DateTime updatedAt;

  String dayNameKey() => 'workout_day_${_dayKeys[dayOfWeek]}';

  static const _dayKeys = [
    'sat',
    'sun',
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
  ];

  factory WorkoutScheduleDayModel.fromJson(Map<String, dynamic> json) {
    return WorkoutScheduleDayModel(
      id: json['id'] as String,
      programId: json['program_id'] as String,
      traineeId: json['trainee_id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      dayType: WorkoutDayType.fromString(json['day_type'] as String?),
      label: json['label'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  WorkoutScheduleDayModel copyWith({
    WorkoutDayType? dayType,
    String? label,
  }) {
    return WorkoutScheduleDayModel(
      id: id,
      programId: programId,
      traineeId: traineeId,
      dayOfWeek: dayOfWeek,
      dayType: dayType ?? this.dayType,
      label: label ?? this.label,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class WorkoutExerciseModel {
  const WorkoutExerciseModel({
    required this.id,
    required this.scheduleDayId,
    required this.traineeId,
    required this.trainerId,
    required this.name,
    this.sets,
    this.reps,
    this.targetWeightKg,
    this.videoUrl,
    this.photoPath,
    this.photoUrl,
    this.notes,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String scheduleDayId;
  final String traineeId;
  final String trainerId;
  final String name;
  final int? sets;
  final int? reps;
  final double? targetWeightKg;
  final String? videoUrl;
  final String? photoPath;
  final String? photoUrl;
  final String? notes;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseModel(
      id: json['id'] as String,
      scheduleDayId: json['schedule_day_id'] as String,
      traineeId: json['trainee_id'] as String,
      trainerId: json['trainer_id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      targetWeightKg: _toDouble(json['target_weight_kg']),
      videoUrl: json['video_url'] as String?,
      photoPath: json['photo_path'] as String?,
      notes: json['notes'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson({
    required String scheduleDayId,
    required String traineeId,
    required String trainerId,
    required int sortOrder,
  }) {
    return {
      'schedule_day_id': scheduleDayId,
      'trainee_id': traineeId,
      'trainer_id': trainerId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'target_weight_kg': targetWeightKg,
      'video_url': videoUrl,
      'photo_path': photoPath,
      'notes': notes,
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'target_weight_kg': targetWeightKg,
      'video_url': videoUrl,
      'photo_path': photoPath,
      'notes': notes,
    };
  }

  WorkoutExerciseModel copyWith({
    String? name,
    int? sets,
    int? reps,
    double? targetWeightKg,
    String? videoUrl,
    String? photoPath,
    String? photoUrl,
    String? notes,
    bool clearNotes = false,
    bool clearPhoto = false,
    bool clearVideo = false,
  }) {
    return WorkoutExerciseModel(
      id: id,
      scheduleDayId: scheduleDayId,
      traineeId: traineeId,
      trainerId: trainerId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      videoUrl: clearVideo ? null : (videoUrl ?? this.videoUrl),
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      notes: clearNotes ? null : (notes ?? this.notes),
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class WorkoutDayArgs {
  const WorkoutDayArgs({
    required this.scheduleDay,
    required this.traineeId,
    this.canManage = false,
  });

  final WorkoutScheduleDayModel scheduleDay;
  final String traineeId;
  final bool canManage;
}

class ExerciseFormArgs {
  const ExerciseFormArgs({
    required this.scheduleDay,
    required this.traineeId,
    this.exercise,
  });

  final WorkoutScheduleDayModel scheduleDay;
  final String traineeId;
  final WorkoutExerciseModel? exercise;

  bool get isEditing => exercise != null;
}

class WorkoutWeightTrialModel {
  const WorkoutWeightTrialModel({
    required this.id,
    required this.scheduleDayId,
    required this.traineeId,
    required this.trainerId,
    required this.trialDate,
    this.note,
    this.scheduleDay,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String scheduleDayId;
  final String traineeId;
  final String trainerId;
  final DateTime trialDate;
  final String? note;
  final WorkoutScheduleDayModel? scheduleDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isToday => WorkoutDateUtils.isSameDate(trialDate, DateTime.now());

  bool get isUpcoming =>
      WorkoutDateUtils.dateOnly(trialDate)
          .compareTo(WorkoutDateUtils.dateOnly(DateTime.now())) >=
      0;

  String get scheduleDayLabel {
    if (scheduleDay == null) return '';
    if (scheduleDay!.label.isNotEmpty) return scheduleDay!.label;
    return scheduleDay!.dayNameKey();
  }

  factory WorkoutWeightTrialModel.fromJson(Map<String, dynamic> json) {
    final dayRaw = json['workout_schedule_days'];
    return WorkoutWeightTrialModel(
      id: json['id'] as String,
      scheduleDayId: json['schedule_day_id'] as String,
      traineeId: json['trainee_id'] as String,
      trainerId: json['trainer_id'] as String,
      trialDate: WorkoutDateUtils.parseDateOnly(json['trial_date'] as String),
      note: json['note'] as String?,
      scheduleDay: dayRaw != null
          ? WorkoutScheduleDayModel.fromJson(
              Map<String, dynamic>.from(dayRaw as Map),
            )
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson({
    required String scheduleDayId,
    required String traineeId,
    required String trainerId,
    required DateTime trialDate,
  }) {
    return {
      'schedule_day_id': scheduleDayId,
      'trainee_id': traineeId,
      'trainer_id': trainerId,
      'trial_date': WorkoutDateUtils.dateOnly(trialDate),
      'note': note,
    };
  }
}

abstract final class WorkoutDateUtils {
  static String dateOnly(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static DateTime parseDateOnly(String value) {
    final parts = value.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static bool isSameDate(DateTime a, DateTime b) =>
      dateOnly(a) == dateOnly(b);
}
