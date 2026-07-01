import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/controllers/activity_controller.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/widgets/activity_streak_card.dart';
import 'package:soccer_sys/modules/activity/widgets/edit_step_goal_sheet.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_progress_ring.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_stat_row.dart';
import 'package:soccer_sys/modules/activity/widgets/steps_week_chart.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/home/widgets/home_stat_card.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TraineeStepsTab extends GetView<ActivityController> {
  const TraineeStepsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final user = auth.currentUser.value;
      final status = controller.todayStatus;

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
                      'nav_progress'.tr,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'activity_subtitle'.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (!controller.pedometerAvailable) ...[
                      const SizedBox(height: AppSpacing.md),
                      GlassContainer(
                        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                        child: Text(
                          controller.pedometerErrorKey.tr,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                    if (controller.errorMessage.value.isNotEmpty &&
                        controller.pedometerAvailable) ...[
                      const SizedBox(height: AppSpacing.md),
                      GlassContainer(
                        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                    if (controller.goalReached) ...[
                      const SizedBox(height: AppSpacing.md),
                      GlassContainer(
                        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'activity_goal_congrats'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                  if (controller.extraStepsBeyondGoal > 0) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'activity_steps_beyond_goal'.trParams({
                                        'extra':
                                            '${controller.extraStepsBeyondGoal}',
                                      }),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'activity_keep_going'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ActivityStreakCard(stats: controller.streakStats.value),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: StepsProgressRing(
                        steps: controller.todaySteps.value,
                        goal: controller.stepGoal,
                        statusLabel: _statusLabel(status),
                        statusColor: _statusColor(status),
                        goalReached: controller.goalReached,
                        extraSteps: controller.extraStepsBeyondGoal,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: TextButton(
                        onPressed: () => EditStepGoalSheet.show(
                          currentGoal: controller.stepGoal,
                          onSave: controller.updateStepGoal,
                        ),
                        child: Text(
                          '${'activity_daily_goal'.tr}: ${controller.stepGoal}',
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
                    HomeQuickTile(
                      icon: Icons.restaurant_menu,
                      title: 'nutrition_title'.tr,
                      subtitle: 'nutrition_tile_subtitle'.tr,
                      onTap: () => Get.toNamed(AppRoutes.nutritionMeals),
                    ),
                    HomeQuickTile(
                      icon: Icons.photo_library_outlined,
                      title: 'progress_gallery_tile_title'.tr,
                      subtitle: 'progress_gallery_tile_subtitle'.tr,
                      onTap: () => Get.toNamed(AppRoutes.progressGallery),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'trainee_progress_subtitle'.tr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: HomeStatCard(
                            icon: Icons.monitor_weight_outlined,
                            label: 'trainee_current_weight'.tr,
                            value: user?.currentWeight != null
                                ? '${user!.currentWeight} kg'
                                : '—',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: HomeStatCard(
                            icon: Icons.flag_outlined,
                            label: 'trainee_target_weight'.tr,
                            value: user?.targetWeight != null
                                ? '${user!.targetWeight} kg'
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'trainee_fitness_goal'.tr,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            user?.fitnessGoal ?? 'trainee_no_goal_set'.tr,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
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
      DailyActivityModel? match;
      for (final a in controller.weekActivities) {
        if (_sameDay(a.activityDate, date)) {
          match = a;
          break;
        }
      }
      if (_sameDay(date, today) && match == null && controller.todaySteps.value > 0) {
        return DailyActivityModel(
          id: '',
          userId: '',
          activityDate: date,
          steps: controller.todaySteps.value,
          calories: controller.todayCalories,
          distanceKm: controller.todayDistanceKm,
          goalSteps: controller.stepGoal,
          source: 'pedometer',
          createdAt: date,
          updatedAt: date,
        );
      }
      return match;
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
