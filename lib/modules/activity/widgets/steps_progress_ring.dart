import 'package:flutter/material.dart';
import 'package:soccer_sys/core/theme/tokens.dart';

class StepsProgressRing extends StatelessWidget {
  const StepsProgressRing({
    super.key,
    required this.steps,
    required this.goal,
    required this.statusLabel,
    required this.statusColor,
    this.goalReached = false,
    this.extraSteps = 0,
  });

  final int steps;
  final int goal;
  final String statusLabel;
  final Color statusColor;
  final bool goalReached;
  final int extraSteps;

  @override
  Widget build(BuildContext context) {
    final ringProgress =
        goal <= 0 ? 0.0 : (steps / goal).clamp(0.0, 1.0);
    final displayPercent =
        goal <= 0 ? 0 : (steps / goal * 100).round();

    return GlassLikeRing(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: ringProgress,
                    strokeWidth: 12,
                    backgroundColor: AppColors.surfaceBorder,
                    color: goalReached ? AppColors.primary : AppColors.primary,
                  ),
                ),
                if (goalReached)
                  Positioned(
                    top: 8,
                    child: Icon(
                      Icons.emoji_events,
                      color: AppColors.primary.withValues(alpha: 0.9),
                      size: 22,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$steps',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: goalReached ? AppColors.primary : null,
                          ),
                    ),
                    Text(
                      '/ $goal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      '$displayPercent%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (goalReached && extraSteps > 0) ...[
                      SizedBox(height: 2),
                      Text(
                        '+$extraSteps',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassLikeRing extends StatelessWidget {
  const GlassLikeRing({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
