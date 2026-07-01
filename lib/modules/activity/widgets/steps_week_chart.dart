import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class StepsWeekChart extends StatelessWidget {
  const StepsWeekChart({
    super.key,
    required this.days,
    required this.goal,
    required this.onDayTap,
  });

  final List<DailyActivityModel?> days;
  final int goal;
  final void Function(DateTime date, DailyActivityModel? activity) onDayTap;

  @override
  Widget build(BuildContext context) {
    final maxSteps = days.fold<int>(
      goal,
      (max, d) => d == null ? max : (d.steps > max ? d.steps : max),
    );

    return GlassContainer(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'activity_last_7_days'.tr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (index) {
                final activity = days[index];
                final date = activity?.activityDate ??
                    DateTime.now().subtract(Duration(days: 6 - index));
                final steps = activity?.steps ?? 0;
                final heightFactor =
                    maxSteps <= 0 ? 0.0 : (steps / maxSteps).clamp(0.05, 1.0);
                final metGoal = steps >= goal;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(date, activity),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 3,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            steps > 0 ? '$steps' : '',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                ),
                          ),
                          SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: heightFactor,
                                widthFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: metGoal
                                        ? AppColors.primary
                                        : AppColors.primary
                                            .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat.E().format(date),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
