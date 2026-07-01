import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/controllers/activity_controller.dart';
import 'package:soccer_sys/modules/activity/widgets/activity_streak_card.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/home/controllers/home_controller.dart';
import 'package:soccer_sys/modules/home/controllers/trainee_dashboard_controller.dart';
import 'package:soccer_sys/modules/home/widgets/home_header.dart';
import 'package:soccer_sys/modules/home/widgets/home_stat_card.dart';
import 'package:soccer_sys/modules/home/widgets/trainee_dashboard_cards.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TraineeDashboardTab extends GetView<TraineeDashboardController> {
  const TraineeDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    final activityRegistered = Get.isRegistered<ActivityController>();
    final activity =
        activityRegistered ? Get.find<ActivityController>() : null;

    return Obx(() {
      final isLoading = controller.status.value.isLoading &&
          controller.todayScheduleDay.value == null &&
          controller.todayMeals.isEmpty;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.refreshTodayPlan,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(
                user: user,
                subtitle: 'trainee_dashboard_subtitle'.tr,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user?.isTrainee == true && !user!.hasTrainer) ...[
                      GlassContainer(
                        padding:
                            const EdgeInsetsDirectional.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'coaching_no_trainer_title'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'coaching_no_trainer_subtitle'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FilledButton(
                              onPressed: () =>
                                  Get.toNamed(AppRoutes.chooseTrainer),
                              child:
                                  Text('coaching_choose_trainer_action'.tr),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    const TraineeTodayOverviewCard(),
                    const SizedBox(height: AppSpacing.lg),
                    HomeSectionTitle(title: 'dashboard_activity_summary'.tr),
                    Obx(() {
                      final steps = activity?.todaySteps.value ?? 0;
                      final goal = activity?.stepGoal ?? 10000;
                      final progress = goal > 0
                          ? (steps / goal).clamp(0.0, 1.0)
                          : 0.0;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: HomeStatCard(
                                  icon: Icons.directions_walk_outlined,
                                  label: 'trainee_stat_today_steps'.tr,
                                  value: '$steps / $goal',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: HomeStatCard(
                                  icon: Icons.route_outlined,
                                  label: 'activity_distance'.tr,
                                  value: activity != null
                                      ? '${activity.todayDistanceKm.toStringAsFixed(2)} km'
                                      : '—',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: HomeStatCard(
                                  icon: Icons.local_fire_department_outlined,
                                  label: 'dashboard_calories_burned'.tr,
                                  value: activity != null
                                      ? '${activity.todayCalories.toStringAsFixed(0)} kcal'
                                      : '—',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: HomeStatCard(
                                  icon: Icons.restaurant_outlined,
                                  label: 'dashboard_meal_calories'.tr,
                                  value: '${controller.totalMealCalories} kcal',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          GlassContainer(
                            padding: const EdgeInsetsDirectional.all(
                              AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'activity_daily_goal'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${(progress * 100).round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: AppColors.inputFill,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                    if (activity != null)
                      Obx(() {
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: AppSpacing.md,
                          ),
                          child: ActivityStreakCard(
                            stats: activity.streakStats.value,
                            compact: true,
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.lg),
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.lg,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else ...[
                      const TraineeTodayWorkoutSection(),
                      const SizedBox(height: AppSpacing.lg),
                      const TraineeTodayNutritionSection(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    HomeSectionTitle(title: 'dashboard_quick_access'.tr),
                    HomeQuickTile(
                      icon: Icons.fitness_center_outlined,
                      title: 'nav_workouts'.tr,
                      subtitle: 'workout_tile_subtitle'.tr,
                      onTap: () => Get.find<HomeController>().changeTab(1),
                    ),
                    HomeQuickTile(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'nutrition_title'.tr,
                      subtitle: 'dashboard_view_meals'.tr,
                      onTap: controller.openNutrition,
                    ),
                    HomeQuickTile(
                      icon: Icons.show_chart_outlined,
                      title: 'nav_progress'.tr,
                      subtitle: 'trainee_progress_subtitle'.tr,
                      onTap: () => Get.find<HomeController>().changeTab(3),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
