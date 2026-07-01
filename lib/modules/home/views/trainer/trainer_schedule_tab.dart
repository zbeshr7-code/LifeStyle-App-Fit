import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/home/widgets/home_stat_card.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TrainerScheduleTab extends StatelessWidget {
  const TrainerScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'nav_schedule'.tr,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'trainer_schedule_subtitle'.tr,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                HomeQuickTile(
                  icon: Icons.fitness_center,
                  title: 'trainer_session_morning'.tr,
                  subtitle: '09:00 — 10:00',
                ),
                HomeQuickTile(
                  icon: Icons.sports_soccer,
                  title: 'trainer_session_afternoon'.tr,
                  subtitle: '16:00 — 17:30',
                ),
                SizedBox(height: AppSpacing.md),
                GlassContainer(
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'trainer_schedule_hint'.tr,
                          textAlign: TextAlign.start,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
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
    );
  }
}
