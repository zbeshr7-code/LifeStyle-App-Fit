import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/modules/workouts/repositories/workout_repository.dart';

class WorkoutWeeklyController extends GetxController {
  WorkoutWeeklyController(
    this._repository, {
    required this.traineeId,
    this.canManage = false,
  });

  final WorkoutRepository _repository;
  final String traineeId;
  final bool canManage;

  final program = Rxn<WorkoutProgramModel>();
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final isSaving = false.obs;
  final weightTrials = <WorkoutWeightTrialModel>[].obs;

  WorkoutWeightTrialModel? get todayWeightTrial {
    for (final trial in weightTrials) {
      if (trial.isToday) return trial;
    }
    return null;
  }

  List<WorkoutWeightTrialModel> trialsForDay(String scheduleDayId) =>
      weightTrials
          .where((trial) => trial.scheduleDayId == scheduleDayId)
          .toList();

  bool dayHasUpcomingTrial(String scheduleDayId) =>
      trialsForDay(scheduleDayId).any((trial) => trial.isUpcoming);

  @override
  void onInit() {
    super.onInit();
    loadProgram();
  }

  Future<void> loadProgram() async {
    status.value = RxStatus.loading();
    final result = await _repository.fetchProgram(
      traineeId: traineeId,
      ensureIfMissing: canManage,
    );
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    program.value = result.program;
    await _loadWeightTrials();
    status.value = RxStatus.success();
  }

  Future<void> _loadWeightTrials() async {
    final result = await _repository.fetchWeightTrials(
      traineeId: traineeId,
      fromDate: DateTime.now().subtract(const Duration(days: 14)),
    );
    if (result.failure != null) return;
    weightTrials.assignAll(result.trials);
  }

  Future<void> updateProgramName(String name) async {
    final current = program.value;
    if (current == null || name.trim().isEmpty) return;

    isSaving.value = true;
    final failure = await _repository.updateProgramName(
      programId: current.id,
      name: name.trim(),
    );
    isSaving.value = false;
    if (failure != null) {
      Get.snackbar('', failure.message.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    program.value = current.copyWith(name: name.trim());
  }

  Future<void> updateDay({
    required WorkoutScheduleDayModel day,
    required WorkoutDayType dayType,
    required String label,
  }) async {
    if (!canManage) return;

    isSaving.value = true;
    final result = await _repository.updateScheduleDay(
      day: day,
      dayType: dayType,
      label: label.trim(),
    );
    isSaving.value = false;
    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final current = program.value;
    if (current == null || result.day == null) return;
    final days = current.scheduleDays.map((d) {
      return d.id == day.id ? result.day! : d;
    }).toList();
    program.value = current.copyWith(scheduleDays: days);
  }

  void openDay(WorkoutScheduleDayModel day) {
    if (!day.dayType.hasExercises) {
      Get.snackbar('', 'workout_rest_day_message'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.toNamed(
      AppRoutes.workoutDay,
      arguments: WorkoutDayArgs(
        scheduleDay: day,
        traineeId: traineeId,
        canManage: canManage,
      ),
    );
  }

  Future<void> showEditProgramNameDialog() async {
    final current = program.value;
    if (current == null) return;

    final controller = TextEditingController(text: current.name);
    final name = await Get.dialog<String>(
      AlertDialog(
        title: Text('workout_edit_program_name'.tr),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'workout_program_name'.tr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('chat_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text),
            child: Text('profile_save'.tr),
          ),
        ],
      ),
    );
    if (name == null) return;
    await updateProgramName(name);
  }

  Future<void> showEditDayDialog(WorkoutScheduleDayModel day) async {
    if (!canManage) return;

    final labelController = TextEditingController(text: day.label);
    var selectedType = day.dayType;

    final saved = await Get.dialog<bool>(
      AlertDialog(
        title: Text('workout_edit_day'.tr),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<WorkoutDayType>(
                  segments: [
                    ButtonSegment(
                      value: WorkoutDayType.workout,
                      label: Text('workout_type_workout'.tr),
                      icon: const Icon(Icons.fitness_center, size: 16),
                    ),
                    ButtonSegment(
                      value: WorkoutDayType.cardio,
                      label: Text('workout_type_cardio'.tr),
                      icon: const Icon(Icons.favorite, size: 16),
                    ),
                    ButtonSegment(
                      value: WorkoutDayType.rest,
                      label: Text('workout_type_rest'.tr),
                      icon: const Icon(Icons.hotel, size: 16),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (value) {
                    setState(() => selectedType = value.first);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'workout_day_label'.tr,
                    hintText: 'workout_day_label_hint'.tr,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('chat_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('profile_save'.tr),
          ),
        ],
      ),
    );

    if (saved != true) return;
    await updateDay(
      day: day,
      dayType: selectedType,
      label: labelController.text,
    );
  }

  Future<void> showScheduleWeightTrialDialog(
    WorkoutScheduleDayModel day,
  ) async {
    if (!canManage) return;
    if (!day.dayType.hasExercises) {
      Get.snackbar('', 'workout_weight_trial_requires_workout'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final noteController = TextEditingController();
    var selectedDate = DateTime.now();

    final saved = await Get.dialog<bool>(
      AlertDialog(
        title: Text('workout_weight_trial_add'.tr),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  day.label.isNotEmpty ? day.label : day.dayNameKey().tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(selectedDate),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'workout_weight_trial_note'.tr,
                    hintText: 'workout_weight_trial_note_hint'.tr,
                  ),
                  maxLines: 2,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('chat_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('profile_save'.tr),
          ),
        ],
      ),
    );

    if (saved != true) return;

    isSaving.value = true;
    final result = await _repository.createWeightTrial(
      scheduleDayId: day.id,
      traineeId: traineeId,
      trialDate: selectedDate,
      note: noteController.text,
    );
    isSaving.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await _loadWeightTrials();
    Get.snackbar('', 'workout_weight_trial_saved'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> deleteWeightTrial(WorkoutWeightTrialModel trial) async {
    if (!canManage) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('workout_weight_trial_delete_title'.tr),
        content: Text('workout_weight_trial_delete_message'.tr),
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

    isSaving.value = true;
    final failure = await _repository.deleteWeightTrial(trial.id);
    isSaving.value = false;

    if (failure != null) {
      Get.snackbar('', failure.message.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await _loadWeightTrials();
  }
}
