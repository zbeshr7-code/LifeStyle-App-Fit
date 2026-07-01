import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/home/widgets/home_stat_card.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TraineeProgressTab extends GetView<AuthController> {
  const TraineeProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser.value;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'nav_progress'.tr,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'trainee_progress_subtitle'.tr,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'trainee_fitness_goal'.tr,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        user?.fitnessGoal ?? 'trainee_no_goal_set'.tr,
                        textAlign: TextAlign.start,
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
    );
  }
}
