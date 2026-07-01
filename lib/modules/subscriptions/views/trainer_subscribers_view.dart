import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_subscribers_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_enums.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';

class TrainerSubscribersView extends GetView<TrainerSubscribersController> {
  const TrainerSubscribersView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('subscription_subscribers_title'.tr),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openAssign,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.status.value.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.status.value.isError) {
          return Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.errorMessage.value.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: controller.loadSubscribers,
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.status.value.isEmpty) {
          return Center(child: Text('subscription_no_subscribers'.tr));
        }

        return RefreshIndicator(
          onRefresh: controller.loadSubscribers,
          child: ListView.builder(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            itemCount: controller.subscribers.length,
            itemBuilder: (context, index) {
              final s = controller.subscribers[index];
              return Card(
                color: AppColors.surfaceSolid,
                margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: s.avatarUrl != null
                        ? NetworkImage(s.avatarUrl!)
                        : null,
                    child: s.avatarUrl == null
                        ? Text(s.fullName.isNotEmpty ? s.fullName[0] : '?')
                        : null,
                  ),
                  title: Text(s.fullName),
                  subtitle: Text(
                    '${s.planTitle}\n${dateFormat.format(s.startsAt.toLocal())} → ${dateFormat.format(s.endsAt.toLocal())}',
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: (s.isActive ? AppColors.primary : AppColors.error)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _statusLabel(s),
                      style: TextStyle(
                        fontSize: 12,
                        color: _statusColor(s),
                      ),
                    ),
                  ),
                  onTap: () => controller.openEdit(s),
                ),
              );
            },
          ),
        );
      }),
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

  Color _statusColor(TrainerSubscriberModel s) {
    if (s.isActive) return AppColors.primary;
    return switch (s.status) {
      SubscriptionStatus.pending => AppColors.textSecondary,
      _ => AppColors.error,
    };
  }
}
