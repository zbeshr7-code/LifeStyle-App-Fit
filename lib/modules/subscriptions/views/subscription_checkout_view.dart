import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moyasar/moyasar.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_checkout_controller.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class SubscriptionCheckoutView extends GetView<SubscriptionCheckoutController> {
  const SubscriptionCheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = controller.plan;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('subscription_checkout_title'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final error = controller.loadError.value;
        if (error != null) {
          return Center(child: Text(error.tr));
        }

        return ListView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          children: [
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    plan.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '${plan.priceAmount.toStringAsFixed(0)} ${'subscription_currency_sar'.tr}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...plan.features.map(
                    (f) => Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(f)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            if (controller.isFreePlan) ...[
              Obx(
                () => FilledButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.activateFreePlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('subscription_activate_free'.tr),
                ),
              ),
            ] else if (controller.canShowMoyasar) ...[
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'subscription_moyasar_title'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'subscription_moyasar_secure'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    CreditCard(
                      config: controller.paymentConfig!,
                      onPaymentResult: controller.onPaymentResult,
                    ),
                  ],
                ),
              ),
              if (controller.isSubmitting.value) ...[
                SizedBox(height: AppSpacing.lg),
                const Center(child: CircularProgressIndicator()),
              ],
            ] else ...[
              GlassContainer(
                child: Text(
                  'subscription_moyasar_key_missing'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
