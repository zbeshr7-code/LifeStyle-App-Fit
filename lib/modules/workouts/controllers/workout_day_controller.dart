import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/modules/workouts/repositories/workout_repository.dart';

class WorkoutDayController extends GetxController {
  WorkoutDayController(this._repository, this.args);

  final WorkoutRepository _repository;
  final WorkoutDayArgs args;

  final exercises = <WorkoutExerciseModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final isSavingOrder = false.obs;
  final weightTrial = Rxn<WorkoutWeightTrialModel>();

  bool get canManage => args.canManage;
  bool get isWeightTrialDay => weightTrial.value != null;

  WorkoutScheduleDayModel get scheduleDay => args.scheduleDay;

  @override
  void onInit() {
    super.onInit();
    loadExercises();
    _loadWeightTrial();
  }

  Future<void> loadWeightTrial() => _loadWeightTrial();

  Future<void> _loadWeightTrial() async {
    final result = await _repository.fetchWeightTrialForDate(
      traineeId: args.traineeId,
      date: DateTime.now(),
    );
    final trial = result.trial;
    if (trial != null && trial.scheduleDayId == scheduleDay.id) {
      weightTrial.value = trial;
    } else {
      weightTrial.value = null;
    }
  }

  Future<void> loadExercises() async {
    status.value = RxStatus.loading();
    final result =
        await _repository.fetchExercises(scheduleDay.id);
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    exercises.assignAll(result.exercises);
    status.value = RxStatus.success();
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    if (!canManage) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = List<WorkoutExerciseModel>.from(exercises);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    exercises.assignAll(updated);

    isSavingOrder.value = true;
    final failure = await _repository.reorderExercises(
      scheduleDayId: scheduleDay.id,
      exercises: updated,
    );
    isSavingOrder.value = false;
    if (failure != null) {
      Get.snackbar('', failure.message.tr, snackPosition: SnackPosition.BOTTOM);
      await loadExercises();
    }
  }

  Future<void> deleteExercise(WorkoutExerciseModel exercise) async {
    if (!canManage) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('workout_delete_exercise_title'.tr),
        content: Text('workout_delete_exercise_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('chat_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'workout_delete_confirm'.tr,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    status.value = RxStatus.loading();
    final failure = await _repository.deleteExercise(exercise);
    if (failure != null) {
      errorMessage.value = failure.message.tr;
      status.value = RxStatus.error(failure.message.tr);
      return;
    }
    await loadExercises();
  }

  void openAddExercise() {
    if (!canManage) return;
    Get.toNamed(
      AppRoutes.workoutExerciseForm,
      arguments: ExerciseFormArgs(
        scheduleDay: scheduleDay,
        traineeId: args.traineeId,
      ),
    )?.then((_) => loadExercises());
  }

  void openEditExercise(WorkoutExerciseModel exercise) {
    if (!canManage) return;
    Get.toNamed(
      AppRoutes.workoutExerciseForm,
      arguments: ExerciseFormArgs(
        scheduleDay: scheduleDay,
        traineeId: args.traineeId,
        exercise: exercise,
      ),
    )?.then((_) => loadExercises());
  }
}
