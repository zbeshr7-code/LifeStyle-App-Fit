import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/home/controllers/trainer_dashboard_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_enums.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_route_args.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TrainerOverviewCard extends GetView<TrainerDashboardController> {
  const TrainerOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dateLabel = DateFormat.yMMMMEEEEd(Get.locale?.languageCode ?? 'ar')
          .format(DateTime.now());
      final active = controller.activeSubscriptionCount;
      final clients = controller.clientCount;

      return GlassContainer(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'dashboard_today'.tr,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              dateLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'trainer_dashboard_overview_body'.trParams({
                'clients': '$clients',
                'active': '$active',
              }),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    });
  }
}

class TrainerSubscriptionSummaryCard
    extends GetView<TrainerDashboardController> {
  const TrainerSubscriptionSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final revenue = controller.revenueThisMonth.value;
      final pending = controller.pendingSubscriptionCount;
      final withoutSub = controller.clientsWithoutActiveSub;

      return GlassContainer(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'trainer_subscription_summary'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Get.toNamed(AppRoutes.trainerSubscribers),
                  child: Text('trainer_view_all_subscribers'.tr),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(
              icon: Icons.payments_outlined,
              label: 'trainer_revenue_month'.tr,
              value: revenue != null
                  ? '${revenue.paidAmount.toStringAsFixed(0)} ${revenue.currency}'
                  : '—',
            ),
            if (pending > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _MetricRow(
                icon: Icons.hourglass_top_outlined,
                label: 'trainer_stat_pending_subs'.tr,
                value: '$pending',
                valueColor: AppColors.textSecondary,
              ),
            ],
            if (withoutSub > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _MetricRow(
                icon: Icons.person_off_outlined,
                label: 'trainer_stat_without_sub'.tr,
                value: '$withoutSub',
                valueColor: AppColors.error,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class TrainerRecentSubscribersCard
    extends GetView<TrainerDashboardController> {
  const TrainerRecentSubscribersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final recent = controller.recentSubscribers;
      if (recent.isEmpty) {
        return GlassContainer(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Text(
            'trainer_no_active_subscribers'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: Text(
              'trainer_recent_subscribers'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...recent.map(
            (s) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: _SubscriberTile(subscriber: s),
            ),
          ),
        ],
      );
    });
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.primary,
              ),
        ),
      ],
    );
  }
}

class _SubscriberTile extends StatelessWidget {
  const _SubscriberTile({required this.subscriber});

  final TrainerSubscriberModel subscriber;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.Md();
    final statusLabel = _statusLabel(subscriber);
    final statusColor = subscriber.isActive
        ? AppColors.primary
        : AppColors.textSecondary;

    return GlassContainer(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoutes.trainerSubscriptionEdit,
          arguments: TrainerSubscriptionEditArgs(subscriber: subscriber),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: subscriber.avatarUrl != null
                  ? NetworkImage(subscriber.avatarUrl!)
                  : null,
              child: subscriber.avatarUrl == null
                  ? Text(
                      subscriber.fullName.isNotEmpty
                          ? subscriber.fullName[0]
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    subscriber.fullName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subscriber.planTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    '${dateFormat.format(subscriber.startsAt.toLocal())} – ${dateFormat.format(subscriber.endsAt.toLocal())}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(TrainerSubscriberModel s) {
    if (s.isActive) return 'subscription_status_active'.tr;
    return switch (s.status) {
      SubscriptionStatus.cancelled => 'subscription_status_cancelled'.tr,
      SubscriptionStatus.pending => 'subscription_status_pending'.tr,
      _ => 'subscription_status_expired'.tr,
    };
  }
}
