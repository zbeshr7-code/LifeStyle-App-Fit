import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class SubscriptionSuccessView extends StatelessWidget {
  const SubscriptionSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = Get.arguments as TraineeSubscriptionModel?;
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.check_circle, size: 80, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'subscription_success_title'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (sub != null)
                GlassContainer(
                  child: Column(
                    children: [
                      Text(
                        sub.planTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'subscription_period_range'.trParams({
                          'start': dateFormat.format(sub.startsAt.toLocal()),
                          'end': dateFormat.format(sub.endsAt.toLocal()),
                        }),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Get.until((route) => route.settings.name == AppRoutes.home);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text('subscription_go_home'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
