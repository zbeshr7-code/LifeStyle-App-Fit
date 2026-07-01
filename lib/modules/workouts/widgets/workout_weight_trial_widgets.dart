import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class WorkoutWeightTrialBanner extends StatelessWidget {
  const WorkoutWeightTrialBanner({
    super.key,
    required this.trial,
    this.compact = false,
  });

  final WorkoutWeightTrialModel trial;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dayLabel = trial.scheduleDay != null
        ? (trial.scheduleDay!.label.isNotEmpty
            ? trial.scheduleDay!.label
            : trial.scheduleDay!.dayNameKey().tr)
        : trial.scheduleDayLabel.tr;

    return GlassContainer(
      padding: EdgeInsetsDirectional.all(
        compact ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Colors.amber.shade400,
              size: compact ? 20 : 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  trial.isToday
                      ? 'workout_weight_trial_today'.tr
                      : 'workout_weight_trial_scheduled'.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade400,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'workout_weight_trial_message'.trParams({'day': dayLabel}),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (trial.note != null && trial.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    trial.note!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutWeightTrialsList extends StatelessWidget {
  const WorkoutWeightTrialsList({
    super.key,
    required this.trials,
    this.canManage = false,
    this.onDelete,
  });

  final List<WorkoutWeightTrialModel> trials;
  final bool canManage;
  final ValueChanged<WorkoutWeightTrialModel>? onDelete;

  @override
  Widget build(BuildContext context) {
    if (trials.isEmpty) return const SizedBox.shrink();

    final upcoming =
        trials.where((trial) => trial.isUpcoming).toList(growable: false);

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'workout_weight_trials_title'.tr,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...upcoming.map(
          (trial) => Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: GlassContainer(
              padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 18,
                    color: trial.isToday
                        ? Colors.amber.shade400
                        : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          DateFormat.yMMMd(
                            Get.locale?.languageCode ?? 'ar',
                          ).format(trial.trialDate),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          trial.scheduleDay != null
                              ? (trial.scheduleDay!.label.isNotEmpty
                                  ? trial.scheduleDay!.label
                                  : trial.scheduleDay!.dayNameKey().tr)
                              : '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        if (trial.note != null && trial.note!.isNotEmpty)
                          Text(
                            trial.note!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (trial.isToday)
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'workout_weight_trial_badge'.tr,
                        style: TextStyle(
                          color: Colors.amber.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (canManage && onDelete != null)
                    IconButton(
                      onPressed: () => onDelete!(trial),
                      icon: Icon(Icons.delete_outline),
                      color: AppColors.error,
                      iconSize: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WorkoutWeightTrialBadge extends StatelessWidget {
  const WorkoutWeightTrialBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center, size: 12, color: Colors.amber.shade400),
          const SizedBox(width: 4),
          Text(
            'workout_weight_trial_badge'.tr,
            style: TextStyle(
              color: Colors.amber.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
