import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_progress_ring.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_stat_row.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_week_chart.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainee_activity_controller.dart';
import 'package:soccer_sys/modules/home/widgets/home_stat_card.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TraineeActivityTab extends GetView<TraineeActivityController> {
  const TraineeActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.status.value.isLoading &&
          controller.weekActivities.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.status.value.isError &&
          controller.weekActivities.isEmpty) {
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
                onPressed: controller.refreshAll,
                child: Text('retry'.tr),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'trainer_client_tracking_subtitle'.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (controller.goalReached) ...[
                      const SizedBox(height: AppSpacing.md),
                      GlassContainer(
                        padding:
                            const EdgeInsetsDirectional.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'activity_goal_congrats'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: StepsProgressRing(
                        steps: controller.todaySteps,
                        goal: controller.stepGoal,
                        statusLabel: _statusLabel(controller.todayStatus),
                        statusColor: _statusColor(controller.todayStatus),
                        goalReached: controller.goalReached,
                        extraSteps: controller.extraStepsBeyondGoal,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        '${'activity_daily_goal'.tr}: ${controller.stepGoal}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    StepsStatRow(
                      calories: controller.todayCalories,
                      distanceKm: controller.todayDistanceKm,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    StepsWeekChart(
                      days: _buildWeekDays(),
                      goal: controller.stepGoal,
                      onDayTap: (date, activity) =>
                          controller.openDayDetail(date, activity: activity),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HomeQuickTile(
                      icon: Icons.history,
                      title: 'activity_see_history'.tr,
                      subtitle: 'activity_see_history_desc'.tr,
                      onTap: controller.openHistory,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<DailyActivityModel?> _buildWeekDays() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - index));
      for (final a in controller.weekActivities) {
        if (_sameDay(a.activityDate, date)) return a;
      }
      return null;
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
