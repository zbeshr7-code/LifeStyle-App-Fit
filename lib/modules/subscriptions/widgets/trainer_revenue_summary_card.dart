import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_plans_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainer_subscription_revenue_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TrainerRevenueSummaryCard extends GetView<TrainerPlansController> {
  const TrainerRevenueSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final revenue = controller.revenue.value;
      final loading = controller.isLoadingRevenue.value;

      return GlassContainer(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'subscription_revenue_title'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DateFilterChips(controller: controller),
            const SizedBox(height: AppSpacing.md),
            if (loading && revenue == null)
              const Center(
                child: Padding(
                  padding: EdgeInsetsDirectional.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (revenue != null)
              _RevenueBody(revenue: revenue)
            else
              Text(
                'subscription_revenue_empty'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _DateFilterChips extends StatelessWidget {
  const _DateFilterChips({required this.controller});

  final TrainerPlansController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preset = controller.revenuePreset.value;
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          _chip(
            context,
            label: 'subscription_revenue_filter_all'.tr,
            selected: preset == RevenueDatePreset.all,
            onTap: () => controller.setRevenuePreset(RevenueDatePreset.all),
          ),
          _chip(
            context,
            label: 'subscription_revenue_filter_month'.tr,
            selected: preset == RevenueDatePreset.thisMonth,
            onTap: () => controller.setRevenuePreset(RevenueDatePreset.thisMonth),
          ),
          _chip(
            context,
            label: 'subscription_revenue_filter_30d'.tr,
            selected: preset == RevenueDatePreset.last30Days,
            onTap: () => controller.setRevenuePreset(RevenueDatePreset.last30Days),
          ),
          _chip(
            context,
            label: controller.customRangeLabel,
            selected: preset == RevenueDatePreset.custom,
            onTap: () => controller.pickCustomDateRange(context),
          ),
        ],
      );
    });
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}

class _RevenueBody extends StatelessWidget {
  const _RevenueBody({required this.revenue});

  final TrainerSubscriptionRevenueModel revenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = 'subscription_currency_sar'.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'subscription_revenue_total'.tr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          '${revenue.totalAmount.toStringAsFixed(0)} $currency',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'subscription_revenue_paid'.tr,
                value:
                    '${revenue.paidAmount.toStringAsFixed(0)} $currency',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatTile(
                label: 'subscription_revenue_count'.tr,
                value: '${revenue.subscriptionCount}',
              ),
            ),
          ],
        ),
        if (revenue.paidAmount < revenue.totalAmount) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            'subscription_revenue_waived_note'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
