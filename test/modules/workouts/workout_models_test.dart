import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';

void main() {
  test('WorkoutProgramModel parses schedule days ordered by day_of_week', () {
    final program = WorkoutProgramModel.fromJson({
      'id': 'p1',
      'trainee_id': 't1',
      'trainer_id': 'tr1',
      'name': 'Push Pull Legs',
      'created_at': '2026-06-04T10:00:00Z',
      'updated_at': '2026-06-04T10:00:00Z',
      'workout_schedule_days': [
        {
          'id': 'd2',
          'program_id': 'p1',
          'trainee_id': 't1',
          'day_of_week': 2,
          'day_type': 'workout',
          'label': 'Legs',
          'created_at': '2026-06-04T10:00:00Z',
          'updated_at': '2026-06-04T10:00:00Z',
        },
        {
          'id': 'd0',
          'program_id': 'p1',
          'trainee_id': 't1',
          'day_of_week': 0,
          'day_type': 'rest',
          'label': '',
          'created_at': '2026-06-04T10:00:00Z',
          'updated_at': '2026-06-04T10:00:00Z',
        },
      ],
    });

    expect(program.name, 'Push Pull Legs');
    expect(program.orderedDays.map((d) => d.dayOfWeek), [0, 2]);
  });

  test('WorkoutScheduleDayModel dayNameKey maps Saturday as index 0', () {
    final saturday = WorkoutScheduleDayModel(
      id: 'd0',
      programId: 'p1',
      traineeId: 't1',
      dayOfWeek: 0,
      dayType: WorkoutDayType.rest,
      label: '',
      createdAt: _ts,
      updatedAt: _ts,
    );
    final friday = WorkoutScheduleDayModel(
      id: 'd6',
      programId: 'p1',
      traineeId: 't1',
      dayOfWeek: 6,
      dayType: WorkoutDayType.cardio,
      label: 'Cardio',
      createdAt: _ts,
      updatedAt: _ts,
    );

    expect(saturday.dayNameKey(), 'workout_day_sat');
    expect(friday.dayNameKey(), 'workout_day_fri');
  });

  test('WorkoutExerciseModel parses numeric fields and hasVideo', () {
    final exercise = WorkoutExerciseModel.fromJson({
      'id': 'e1',
      'schedule_day_id': 'd1',
      'trainee_id': 't1',
      'trainer_id': 'tr1',
      'name': 'Bench Press',
      'sets': 4,
      'reps': 8,
      'target_weight_kg': '60.5',
      'video_url': 'https://youtube.com/watch?v=abc',
      'photo_path': 't1/e1.jpg',
      'notes': 'Controlled tempo',
      'sort_order': 1,
      'created_at': '2026-06-04T10:00:00Z',
      'updated_at': '2026-06-04T10:00:00Z',
    });

    expect(exercise.sets, 4);
    expect(exercise.reps, 8);
    expect(exercise.targetWeightKg, 60.5);
    expect(exercise.hasVideo, isTrue);
    expect(WorkoutDayType.fromString('cardio'), WorkoutDayType.cardio);
    expect(WorkoutDayType.cardio.hasExercises, isTrue);
    expect(WorkoutDayType.rest.hasExercises, isFalse);
  });
}

final _ts = DateTime.utc(2026, 6, 4, 10);
