import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class WorkoutWeeklyTable extends StatelessWidget {
  const WorkoutWeeklyTable({
    super.key,
    required this.days,
    required this.canManage,
    required this.onDayTap,
    this.onDayEdit,
    this.onScheduleTrial,
    this.dayHasTrial,
  });

  final List<WorkoutScheduleDayModel> days;
  final bool canManage;
  final ValueCallback<WorkoutScheduleDayModel> onDayTap;
  final ValueCallback<WorkoutScheduleDayModel>? onDayEdit;
  final ValueCallback<WorkoutScheduleDayModel>? onScheduleTrial;
  final bool Function(String scheduleDayId)? dayHasTrial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(canManage: canManage),
        const SizedBox(height: AppSpacing.sm),
        ...days.map(
          (day) => _DayRow(
            day: day,
            canManage: canManage,
            hasTrial: dayHasTrial?.call(day.id) ?? false,
            onTap: () => onDayTap(day),
            onEdit: canManage && onDayEdit != null
                ? () => onDayEdit!(day)
                : null,
            onScheduleTrial: canManage && onScheduleTrial != null
                ? () => onScheduleTrial!(day)
                : null,
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'workout_col_day'.tr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'workout_col_type'.tr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'workout_col_label'.tr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (canManage) const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.canManage,
    required this.hasTrial,
    required this.onTap,
    this.onEdit,
    this.onScheduleTrial,
  });

  final WorkoutScheduleDayModel day;
  final bool canManage;
  final bool hasTrial;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onScheduleTrial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: GlassContainer(
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    day.dayNameKey().tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(
                        _typeIcon(day.dayType),
                        size: 18,
                        color: _typeColor(day.dayType),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          _typeLabel(day.dayType),
                          style: TextStyle(color: _typeColor(day.dayType)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          day.label.isEmpty ? '—' : day.label,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (hasTrial) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const _TrialDot(),
                      ],
                    ],
                  ),
                ),
                if (canManage) ...[
                  IconButton(
                    onPressed: day.dayType.hasExercises ? onScheduleTrial : null,
                    icon: Icon(
                      Icons.trending_up,
                      size: 20,
                      color: day.dayType.hasExercises
                          ? Colors.amber.shade400
                          : AppColors.iconMuted,
                    ),
                    tooltip: 'workout_weight_trial_add'.tr,
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.primary,
                  ),
                ] else
                  Icon(
                    day.dayType.hasExercises
                        ? (hasTrial
                            ? Icons.fitness_center
                            : Icons.chevron_right)
                        : Icons.hotel,
                    color: hasTrial ? Colors.amber.shade400 : AppColors.iconMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(WorkoutDayType type) => switch (type) {
        WorkoutDayType.workout => Icons.fitness_center,
        WorkoutDayType.cardio => Icons.favorite,
        WorkoutDayType.rest => Icons.hotel,
      };

  Color _typeColor(WorkoutDayType type) => switch (type) {
        WorkoutDayType.workout => AppColors.primary,
        WorkoutDayType.cardio => Colors.redAccent,
        WorkoutDayType.rest => AppColors.textSecondary,
      };

  String _typeLabel(WorkoutDayType type) => switch (type) {
        WorkoutDayType.workout => 'workout_type_workout'.tr,
        WorkoutDayType.cardio => 'workout_type_cardio'.tr,
        WorkoutDayType.rest => 'workout_type_rest'.tr,
      };
}

typedef ValueCallback<T> = void Function(T value);

class _TrialDot extends StatelessWidget {
  const _TrialDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.amber.shade400,
        shape: BoxShape.circle,
      ),
    );
  }
}
