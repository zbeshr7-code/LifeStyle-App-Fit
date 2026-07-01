import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/workouts/controllers/workout_day_controller.dart';
import 'package:soccer_sys/modules/workouts/widgets/workout_exercise_card.dart';
import 'package:soccer_sys/modules/workouts/widgets/workout_weight_trial_widgets.dart';

class WorkoutDayDetailView extends GetView<WorkoutDayController> {
  const WorkoutDayDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final day = controller.scheduleDay;
    final title = day.label.isNotEmpty
        ? day.label
        : day.dayNameKey().tr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(title),
      ),
      floatingActionButton: controller.canManage
          ? FloatingActionButton.extended(
              onPressed: controller.openAddExercise,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              icon: const Icon(Icons.add),
              label: Text('workout_add_exercise'.tr),
            )
          : null,
      body: Obx(() {
        if (controller.status.value.isLoading &&
            controller.exercises.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.status.value.isError &&
            controller.exercises.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.errorMessage.value),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: controller.loadExercises,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (controller.exercises.isEmpty) {
          return Center(
            child: Text(
              controller.canManage
                  ? 'workout_no_exercises_trainer'.tr
                  : 'workout_no_exercises'.tr,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (controller.canManage) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await controller.loadExercises();
              await controller.loadWeightTrial();
            },
            child: _ExerciseList(canManage: true),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await controller.loadExercises();
            await controller.loadWeightTrial();
          },
          child: _ExerciseList(canManage: false),
        );
      }),
    );
  }
}

class _ExerciseList extends GetView<WorkoutDayController> {
  const _ExerciseList({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    if (canManage) {
      return ReorderableListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        buildDefaultDragHandles: false,
        onReorder: controller.reorderExercises,
        children: [
          if (controller.isWeightTrialDay)
            Padding(
              key: const ValueKey('weight_trial_banner'),
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
              child: WorkoutWeightTrialBanner(
                trial: controller.weightTrial.value!,
              ),
            ),
          for (var i = 0; i < controller.exercises.length; i++)
            ReorderableDragStartListener(
              key: ValueKey(controller.exercises[i].id),
              index: i,
              child: WorkoutExerciseCard(
                exercise: controller.exercises[i],
                canManage: true,
                onEdit: () =>
                    controller.openEditExercise(controller.exercises[i]),
                onDelete: () =>
                    controller.deleteExercise(controller.exercises[i]),
              ),
            ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (controller.isWeightTrialDay) ...[
          WorkoutWeightTrialBanner(trial: controller.weightTrial.value!),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final exercise in controller.exercises)
          WorkoutExerciseCard(exercise: exercise),
      ],
    );
  }
}
