import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/bindings/activity_binding.dart';
import 'package:soccer_sys/modules/activity/controllers/activity_controller.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_progress_ring.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_stat_row.dart';
import 'package:soccer_sys/modules/home/widgets/home_stat_card.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class ActivityDayDetailView extends GetView<ActivityDayController> {
  const ActivityDayDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(DateFormat.yMMMd().format(controller.args.date)),
      ),
      body: Obx(() {
        if (controller.status.value.isLoading) {
          return  Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final activityCtrl = Get.isRegistered<ActivityController>()
            ? Get.find<ActivityController>()
            : null;
        final steps = controller.isTraineeView
            ? controller.liveSteps
            : controller.isToday
                ? activityCtrl?.todaySteps.value ?? controller.liveSteps
                : controller.liveSteps;
        final calories = controller.isTraineeView
            ? controller.calories
            : controller.isToday
                ? activityCtrl?.todayCalories ?? controller.calories
                : controller.calories;
        final distanceKm = controller.isTraineeView
            ? controller.distanceKm
            : controller.isToday
                ? activityCtrl?.todayDistanceKm ?? controller.distanceKm
                : controller.distanceKm;
        final status = ActivityMetricsCalculator.statusFor(
          steps: steps,
          goal: controller.goalSteps,
          isToday: controller.isToday,
        );

        final goal = controller.goalSteps;
        final goalReached = goal > 0 && steps >= goal;
        final extraSteps = goalReached ? steps - goal : 0;

        return SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: StepsProgressRing(
                  steps: steps,
                  goal: goal,
                  statusLabel: _statusLabel(status),
                  statusColor: _statusColor(status),
                  goalReached: goalReached,
                  extraSteps: extraSteps,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              StepsStatRow(
                calories: calories,
                distanceKm: distanceKm,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: HomeStatCard(
                      icon: Icons.trending_up,
                      label: 'activity_week_avg'.tr,
                      value: '${controller.weekAverage.value}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: HomeStatCard(
                      icon: Icons.flag_outlined,
                      label: 'activity_daily_goal'.tr,
                      value: '${controller.goalSteps}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'activity_day_summary'.tr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _row('activity_steps'.tr, '$steps'),
                    _row(
                      'activity_calories'.tr,
                      '${calories.round()} kcal',
                    ),
                    _row(
                      'activity_distance'.tr,
                      '${distanceKm.toStringAsFixed(2)} km',
                    ),
                    if (controller.weekAverage.value > 0)
                      _row(
                        'activity_vs_avg'.tr,
                        '${steps - controller.weekAverage.value >= 0 ? '+' : ''}${steps - controller.weekAverage.value}',
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _statusLabel(StepGoalStatus status) => switch (status) {
        StepGoalStatus.reached => 'activity_status_reached'.tr,
        StepGoalStatus.onTrack => 'activity_status_on_track'.tr,
        StepGoalStatus.behind => 'activity_status_behind'.tr,
        StepGoalStatus.noData => 'activity_status_no_data'.tr,
      };

  Color _statusColor(StepGoalStatus status) => switch (status) {
        StepGoalStatus.reached => AppColors.primary,
        StepGoalStatus.onTrack => AppColors.primary,
        StepGoalStatus.behind => AppColors.error,
        StepGoalStatus.noData => AppColors.textSecondary,
      };
}
