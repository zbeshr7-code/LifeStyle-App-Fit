import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/profile/controllers/profile_controller.dart';
import 'package:soccer_sys/modules/profile/widgets/profile_field_tile.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_enums.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';

/// Trainee profile block: current subscription + change plan.
class ProfileSubscriptionSection extends StatelessWidget {
  const ProfileSubscriptionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthController>().currentUser.value;
    if (user == null || !user.isTrainee) return const SizedBox.shrink();

    if (!Get.isRegistered<SubscriptionAccessController>()) {
      return const SizedBox.shrink();
    }

    final access = Get.find<SubscriptionAccessController>();
    final profile = Get.find<ProfileController>();

    return Obx(() {
      if (access.isLoading.value && access.activeSubscription.value == null) {
        return const Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (!user.hasTrainer) {
        return Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'subscription_need_trainer_body'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: profile.openChooseTrainer,
                child: Text('subscription_choose_trainer'.tr),
              ),
            ],
          ),
        );
      }

      final sub = access.activeSubscription.value;
      if (sub == null || !sub.isActive) {
        return Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'profile_subscription_none'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: profile.openSubscriptionPlans,
                child: Text('profile_subscription_subscribe'.tr),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActivePlanSummary(subscription: sub),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: profile.openSubscriptionPlans,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text('profile_subscription_change_plan'.tr),
            ),
          ],
        ),
      );
    });
  }
}

class _ActivePlanSummary extends StatelessWidget {
  const _ActivePlanSummary({required this.subscription});

  final TraineeSubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    final price =
        '${subscription.planPrice.toStringAsFixed(0)} ${'subscription_currency_sar'.tr}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileFieldTile(
          label: 'profile_current_plan'.tr,
          value: subscription.planTitle,
        ),
        ProfileFieldTile(
          label: 'subscription_field_price'.tr,
          value: price,
        ),
        ProfileFieldTile(
          label: 'profile_subscription_status'.tr,
          value: _statusLabel(subscription.status),
        ),
        ProfileFieldTile(
          label: 'subscription_starts_at'.tr,
          value: dateFmt.format(subscription.startsAt.toLocal()),
        ),
        ProfileFieldTile(
          label: 'subscription_ends_at'.tr,
          value: dateFmt.format(subscription.endsAt.toLocal()),
          isLast: true,
        ),
      ],
    );
  }

  String _statusLabel(SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.active => 'subscription_status_active'.tr,
      SubscriptionStatus.expired => 'subscription_status_expired'.tr,
      SubscriptionStatus.cancelled => 'subscription_status_cancelled'.tr,
      SubscriptionStatus.pending => 'subscription_status_pending'.tr,
    };
  }
}
