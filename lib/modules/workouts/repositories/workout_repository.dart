import 'dart:typed_data';

import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/modules/workouts/services/workout_service.dart';
import 'package:soccer_sys/modules/workouts/services/workout_storage_service.dart';

class WorkoutRepository {
  WorkoutRepository(this._workoutService, this._storageService);

  final WorkoutService _workoutService;
  final WorkoutStorageService _storageService;

  Future<({Failure? failure, WorkoutProgramModel? program})> fetchProgram({
    required String traineeId,
    bool ensureIfMissing = false,
  }) async {
    try {
      if (ensureIfMissing) {
        await _workoutService.ensureProgram(traineeId);
      }
      final data = await _workoutService.fetchProgram(traineeId);
      if (data == null) {
        return (failure: null, program: null);
      }
      return (
        failure: null,
        program: WorkoutProgramModel.fromJson(data),
      );
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        program: null,
      );
    }
  }

  Future<Failure?> updateProgramName({
    required String programId,
    required String name,
  }) async {
    try {
      await _workoutService.updateProgramName(programId, name);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<({Failure? failure, WorkoutScheduleDayModel? day})> updateScheduleDay({
    required WorkoutScheduleDayModel day,
    required WorkoutDayType dayType,
    required String label,
  }) async {
    try {
      final data = await _workoutService.updateScheduleDay(
        dayId: day.id,
        dayType: dayType,
        label: label,
      );
      return (
        failure: null,
        day: WorkoutScheduleDayModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), day: null);
    }
  }

  Future<({Failure? failure, List<WorkoutExerciseModel> exercises})>
      fetchExercises(String scheduleDayId) async {
    try {
      final data = await _workoutService.fetchExercises(scheduleDayId);
      final exercises = await _attachPhotoUrls(
        data.map(WorkoutExerciseModel.fromJson).toList(),
      );
      return (failure: null, exercises: exercises);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        exercises: <WorkoutExerciseModel>[],
      );
    }
  }

  Future<({Failure? failure, WorkoutExerciseModel? exercise})> createExercise({
    required WorkoutExerciseModel draft,
    required String scheduleDayId,
    required String traineeId,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    try {
      final trainerId = _workoutService.currentUserId;
      if (trainerId == null) throw Exception('Not authenticated');

      final sortOrder =
          await _workoutService.nextExerciseSortOrder(scheduleDayId);
      final created = await _workoutService.createExercise(
        draft.toInsertJson(
          scheduleDayId: scheduleDayId,
          traineeId: traineeId,
          trainerId: trainerId,
          sortOrder: sortOrder,
        ),
      );

      var exercise = WorkoutExerciseModel.fromJson(created);
      if (photoBytes != null) {
        try {
          final path = await _storageService.uploadPhoto(
            traineeId: traineeId,
            exerciseId: exercise.id,
            bytes: photoBytes,
            fileName: photoFileName ?? 'exercise.jpg',
          );
          final updated = await _workoutService.updateExercise(
            exercise.id,
            {'photo_path': path},
          );
          exercise = WorkoutExerciseModel.fromJson(updated);
        } catch (error) {
          final withUrl = await _attachPhotoUrls([exercise]);
          return (
            failure: FailureMapper.fromException(error),
            exercise: withUrl.first,
          );
        }
      }

      final withUrl = await _attachPhotoUrls([exercise]);
      return (failure: null, exercise: withUrl.first);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), exercise: null);
    }
  }

  Future<({Failure? failure, WorkoutExerciseModel? exercise})> updateExercise({
    required WorkoutExerciseModel exercise,
    Uint8List? photoBytes,
    String? photoFileName,
    bool removePhoto = false,
  }) async {
    try {
      var photoPath = exercise.photoPath;
      Failure? photoFailure;

      if (removePhoto && photoPath != null) {
        await _storageService.deletePath(photoPath);
        photoPath = null;
      } else if (photoBytes != null) {
        try {
          photoPath = await _storageService.uploadPhoto(
            traineeId: exercise.traineeId,
            exerciseId: exercise.id,
            bytes: photoBytes,
            fileName: photoFileName ?? 'exercise.jpg',
          );
        } catch (error) {
          photoFailure = FailureMapper.fromException(error);
        }
      }

      final payload = exercise.copyWith(photoPath: photoPath).toUpdateJson();
      if (removePhoto) payload['photo_path'] = null;

      final updated =
          await _workoutService.updateExercise(exercise.id, payload);
      final result = await _attachPhotoUrls([
        WorkoutExerciseModel.fromJson(updated),
      ]);
      return (failure: photoFailure, exercise: result.first);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), exercise: null);
    }
  }

  Future<Failure?> deleteExercise(WorkoutExerciseModel exercise) async {
    try {
      await _storageService.deletePath(exercise.photoPath);
      await _workoutService.deleteExercise(exercise.id);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<Failure?> reorderExercises({
    required String scheduleDayId,
    required List<WorkoutExerciseModel> exercises,
  }) async {
    try {
      await _workoutService.reorderExercises(
        scheduleDayId: scheduleDayId,
        exerciseIds: exercises.map((e) => e.id).toList(),
      );
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<({Failure? failure, List<WorkoutWeightTrialModel> trials})>
      fetchWeightTrials({
    required String traineeId,
    DateTime? fromDate,
  }) async {
    try {
      final data = await _workoutService.fetchWeightTrials(
        traineeId: traineeId,
        fromDate: fromDate,
      );
      return (
        failure: null,
        trials: data.map(WorkoutWeightTrialModel.fromJson).toList(),
      );
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        trials: <WorkoutWeightTrialModel>[],
      );
    }
  }

  Future<({Failure? failure, WorkoutWeightTrialModel? trial})>
      fetchWeightTrialForDate({
    required String traineeId,
    required DateTime date,
  }) async {
    try {
      final data = await _workoutService.fetchWeightTrialForDate(
        traineeId: traineeId,
        date: date,
      );
      if (data == null) return (failure: null, trial: null);
      return (
        failure: null,
        trial: WorkoutWeightTrialModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), trial: null);
    }
  }

  Future<({Failure? failure, WorkoutWeightTrialModel? trial})>
      createWeightTrial({
    required String scheduleDayId,
    required String traineeId,
    required DateTime trialDate,
    String? note,
  }) async {
    try {
      final trainerId = _workoutService.currentUserId;
      if (trainerId == null) throw Exception('Not authenticated');

      final created = await _workoutService.createWeightTrial({
        'schedule_day_id': scheduleDayId,
        'trainee_id': traineeId,
        'trainer_id': trainerId,
        'trial_date': WorkoutDateUtils.dateOnly(trialDate),
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
      });
      return (
        failure: null,
        trial: WorkoutWeightTrialModel.fromJson(created),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), trial: null);
    }
  }

  Future<Failure?> deleteWeightTrial(String trialId) async {
    try {
      await _workoutService.deleteWeightTrial(trialId);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<List<WorkoutExerciseModel>> _attachPhotoUrls(
    List<WorkoutExerciseModel> exercises,
  ) async {
    final result = <WorkoutExerciseModel>[];
    for (final exercise in exercises) {
      if (exercise.photoPath == null || exercise.photoPath!.isEmpty) {
        result.add(exercise);
        continue;
      }
      final url = await _storageService.resolveUrl(exercise.photoPath!);
      result.add(exercise.copyWith(photoUrl: url));
    }
    return result;
  }
}
