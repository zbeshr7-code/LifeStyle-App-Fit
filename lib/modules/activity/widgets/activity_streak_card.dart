import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/utils/activity_streak_calculator.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class ActivityStreakCard extends StatelessWidget {
  const ActivityStreakCard({
    super.key,
    required this.stats,
    this.compact = false,
  });

  final ActivityStreakStats stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = Get.locale?.languageCode ?? 'ar';

    return GlassContainer(
      padding: EdgeInsetsDirectional.all(
        compact ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StreakIcon(streak: stats.currentStreak),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'activity_streak_title'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (stats.hasTenDayBadge) const _TenDayBadge(),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      stats.hasStreak
                          ? 'activity_streak_days'.trParams({
                              'count': '${stats.currentStreak}',
                            })
                          : 'activity_streak_none'.tr,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: stats.hasStreak
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            stats.motivationalKey.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          if (stats.streakStartDate != null && stats.hasStreak) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'activity_streak_since'.trParams({
                'date': DateFormat.yMMMd(locale).format(stats.streakStartDate!),
              }),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (!compact) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: AppColors.surfaceBorder),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'activity_streak_avg_streak'.tr,
                    value: stats.hasStreak
                        ? '${stats.streakAverageSteps}'
                        : '—',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    label: 'activity_streak_avg_7'.tr,
                    value: '${stats.last7DaysAverage}',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    label: 'activity_streak_avg_30'.tr,
                    value: '${stats.last30DaysAverage}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StreakIcon extends StatelessWidget {
  const _StreakIcon({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final color = streak >= 10
        ? Colors.orange.shade400
        : streak >= 7
            ? AppColors.primary
            : streak >= 3
                ? AppColors.primary.withValues(alpha: 0.85)
                : AppColors.iconMuted;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            streak >= 3 ? Icons.local_fire_department : Icons.directions_walk,
            color: color,
            size: 22,
          ),
          if (streak > 0)
            Text(
              '$streak',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _TenDayBadge extends StatelessWidget {
  const _TenDayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'activity_streak_badge_10'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
