import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/home/controllers/trainee_dashboard_controller.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/modules/workouts/widgets/workout_weight_trial_widgets.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TraineeTodayOverviewCard extends GetView<TraineeDashboardController> {
  const TraineeTodayOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = controller.todayScheduleDay.value;
      final dateLabel = DateFormat.yMMMMEEEEd(Get.locale?.languageCode ?? 'ar')
          .format(DateTime.now());

      return GlassContainer(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'dashboard_today'.tr,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                if (day != null) _DayTypeBadge(type: day.dayType),
              ],
            ),
            if (day != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                day.dayNameKey().tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (day.label.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  day.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
            if (controller.programName.value.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                controller.programName.value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (controller.todayWeightTrial.value != null) ...[
              const SizedBox(height: AppSpacing.md),
              WorkoutWeightTrialBanner(
                trial: controller.todayWeightTrial.value!,
                compact: true,
              ),
            ],
            SizedBox(height: AppSpacing.sm),
            Text(
              controller.todayNutritionDayLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    });
  }
}

class _DayTypeBadge extends StatelessWidget {
  const _DayTypeBadge({required this.type});

  final WorkoutDayType type;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (type) {
      WorkoutDayType.workout => (
          'workout_type_workout'.tr,
          Icons.fitness_center,
          AppColors.primary,
        ),
      WorkoutDayType.cardio => (
          'workout_type_cardio'.tr,
          Icons.favorite,
          Colors.redAccent,
        ),
      WorkoutDayType.rest => (
          'workout_type_rest'.tr,
          Icons.hotel,
          AppColors.textSecondary,
        ),
    };

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class TraineeTodayWorkoutSection extends GetView<TraineeDashboardController> {
  const TraineeTodayWorkoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = controller.todayScheduleDay.value;
      final exercises = controller.todayExercises;
      final isLoading = controller.status.value.isLoading;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'dashboard_today_workout'.tr,
            actionLabel: 'dashboard_view_workout'.tr,
            onAction: day?.dayType.hasExercises == true
                ? controller.openTodayWorkout
                : null,
          ),
          if (isLoading && day == null)
            const _LoadingPlaceholder()
          else if (day == null)
            _EmptySection(message: 'dashboard_no_program'.tr)
          else if (!day.dayType.hasExercises)
            _EmptySection(message: 'workout_rest_day_message'.tr)
          else if (exercises.isEmpty)
            _EmptySection(message: 'dashboard_no_exercises_today'.tr)
          else
            GlassContainer(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                children: [
                  for (var i = 0; i < exercises.length && i < 5; i++) ...[
                    if (i > 0) const Divider(height: AppSpacing.lg),
                    _ExerciseRow(exercise: exercises[i]),
                  ],
                  if (exercises.length > 5) ...[
                    const Divider(height: AppSpacing.lg),
                    Text(
                      'dashboard_more_exercises'
                          .trParams({'count': '${exercises.length - 5}'}),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    });
  }
}

class TraineeTodayNutritionSection extends GetView<TraineeDashboardController> {
  const TraineeTodayNutritionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meals = controller.todayMeals;
      final isLoading = controller.status.value.isLoading;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'dashboard_today_nutrition'.tr,
            actionLabel: 'dashboard_view_meals'.tr,
            onAction: controller.openNutrition,
          ),
          if (isLoading && meals.isEmpty)
            const _LoadingPlaceholder()
          else if (meals.isEmpty)
            _EmptySection(message: 'dashboard_no_meals_today'.tr)
          else
            GlassContainer(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < meals.length; i++) ...[
                    if (i > 0) const Divider(height: AppSpacing.lg),
                    _MealRow(meal: meals[i]),
                  ],
                  const Divider(height: AppSpacing.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'dashboard_total_calories'.tr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${controller.totalMealCalories} kcal',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final WorkoutExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final details = <String>[];
    if (exercise.sets != null) details.add('${exercise.sets} ${'workout_sets'.tr}');
    if (exercise.reps != null) {
      details.add('${exercise.reps} ${'workout_reps'.tr}');
    }
    if (exercise.targetWeightKg != null) {
      details.add('${exercise.targetWeightKg} kg');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child:  Icon(
            Icons.fitness_center,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                exercise.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (details.isNotEmpty)
                Text(
                  details.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ),
        if (exercise.hasVideo)
           Icon(Icons.play_circle_outline, color: AppColors.primary),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final NutritionMealModel meal;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child:  Icon(
            Icons.restaurant_outlined,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                meal.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (meal.foodItemLines.isNotEmpty)
                Text(
                  meal.foodItemLines.take(2).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ),
        Text(
          '${meal.calories}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return  GlassContainer(
      padding: EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
