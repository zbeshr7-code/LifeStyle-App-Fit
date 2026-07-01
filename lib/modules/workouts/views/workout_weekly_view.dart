import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/workouts/controllers/workout_weekly_controller.dart';
import 'package:soccer_sys/modules/workouts/widgets/workout_weekly_table.dart';
import 'package:soccer_sys/modules/workouts/widgets/workout_weight_trial_widgets.dart';

class WorkoutWeeklyView extends GetView<WorkoutWeeklyController> {
  const WorkoutWeeklyView({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = Obx(() {
      if (controller.status.value.isLoading &&
          controller.program.value == null) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.status.value.isError &&
          controller.program.value == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.errorMessage.value,
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: controller.loadProgram,
                child: Text('retry'.tr),
              ),
            ],
          ),
        );
      }

      final program = controller.program.value;
      if (program == null) {
        return Center(
          child: Text(
            'workout_empty_trainee'.tr,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadProgram,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (!embedded) ...[
              Text(
                'workout_weekly_subtitle'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    program.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (controller.canManage)
                  IconButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.showEditProgramNameDialog,
                    icon: Icon(Icons.edit_outlined),
                    color: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (controller.todayWeightTrial != null &&
                !controller.canManage) ...[
              WorkoutWeightTrialBanner(
                trial: controller.todayWeightTrial!,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            WorkoutWeeklyTable(
              days: program.orderedDays,
              canManage: controller.canManage,
              onDayTap: controller.openDay,
              onDayEdit: controller.canManage
                  ? controller.showEditDayDialog
                  : null,
              onScheduleTrial: controller.canManage
                  ? controller.showScheduleWeightTrialDialog
                  : null,
              dayHasTrial: controller.dayHasUpcomingTrial,
            ),
            const SizedBox(height: AppSpacing.lg),
            WorkoutWeightTrialsList(
              trials: controller.weightTrials.toList(),
              canManage: controller.canManage,
              onDelete: controller.canManage
                  ? controller.deleteWeightTrial
                  : null,
            ),
          ],
        ),
      );
    });

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('nav_workouts'.tr),
      ),
      body: SafeArea(child: body),
    );
  }
}
