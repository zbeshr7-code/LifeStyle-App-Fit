import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';
import 'package:soccer_sys/modules/subscriptions/widgets/subscription_plan_card.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

/// Blocks trainee content until trainer + active subscription (chat stays open).
class SubscriptionGate extends StatelessWidget {
  const SubscriptionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SubscriptionAccessController>()) {
      return child;
    }

    final access = Get.find<SubscriptionAccessController>();

    return Obx(() {
      if (access.isLoading.value && access.activeSubscription.value == null) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!access.needsTrainer && !access.needsSubscription) {
        return child;
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned.fill(
            child: ClipRect(
              child: AppColors.isDark
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        color: AppColors.background.withValues(alpha: 0.72),
                      ),
                    )
                  : ColoredBox(
                      color: AppColors.background.withValues(alpha: 0.92),
                    ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: access.needsTrainer
                  ? _TrainerRequiredCard()
                  : _SubscriptionRequiredCard(access: access),
            ),
          ),
        ],
      );
    });
  }
}

class _TrainerRequiredCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'subscription_need_trainer_title'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'subscription_need_trainer_body'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Get.toNamed(AppRoutes.chooseTrainer),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text('subscription_choose_trainer'.tr),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionRequiredCard extends StatelessWidget {
  const _SubscriptionRequiredCard({required this.access});

  final SubscriptionAccessController access;

  @override
  Widget build(BuildContext context) {
    final featured = access.featuredPlans
        .where((p) => p.isFeatured)
        .toList();
    final previewPlan = featured.isNotEmpty
        ? featured.first
        : (access.featuredPlans.isNotEmpty
            ? access.featuredPlans.first
            : null);

    return GlassContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'subscription_locked_title'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'subscription_locked_body'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payment, size: 18, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'subscription_moyasar_active'.tr,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ),
          if (previewPlan != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SubscriptionPlanCard(
              plan: previewPlan,
              compact: true,
              onTap: () => Get.toNamed(AppRoutes.subscriptionPlans),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Get.toNamed(AppRoutes.subscriptionPlans),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text('subscription_view_plans'.tr),
          ),
        ],
      ),
    );
  }
}
