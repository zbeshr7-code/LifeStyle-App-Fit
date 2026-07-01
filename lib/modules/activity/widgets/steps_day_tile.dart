import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class StepsDayTile extends StatelessWidget {
  const StepsDayTile({
    super.key,
    required this.activity,
    required this.onTap,
  });

  final DailyActivityModel activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = ActivityMetricsCalculator.statusFor(
      steps: activity.steps,
      goal: activity.goalSteps,
      isToday: false,
    );
    final statusLabel = _statusKey(status).tr;
    final percent = activity.progressPercent.round();

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: GlassContainer(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(activity.activityDate),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '${activity.steps} ${'activity_steps'.tr} · $percent%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      '${activity.calories.round()} kcal · ${activity.distanceKm.toStringAsFixed(2)} km',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: AppColors.iconMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusKey(StepGoalStatus status) => switch (status) {
        StepGoalStatus.reached => 'activity_status_reached',
        StepGoalStatus.onTrack => 'activity_status_on_track',
        StepGoalStatus.behind => 'activity_status_behind',
        StepGoalStatus.noData => 'activity_status_no_data',
      };

  Color _statusColor(StepGoalStatus status) => switch (status) {
        StepGoalStatus.reached => AppColors.primary,
        StepGoalStatus.onTrack => AppColors.primary,
        StepGoalStatus.behind => AppColors.error,
        StepGoalStatus.noData => AppColors.textSecondary,
      };
}
