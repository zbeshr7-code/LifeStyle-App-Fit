import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_subscription_edit_controller.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TrainerSubscriptionEditView
    extends GetView<TrainerSubscriptionEditController> {
  const TrainerSubscriptionEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final sub = controller.subscriber;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('subscription_edit_period_title'.tr),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  sub.planTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('subscription_starts_at'.tr),
              subtitle: Text(dateFormat.format(controller.startsAt.value)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(context, isStart: true),
            ),
          ),
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('subscription_ends_at'.tr),
              subtitle: Text(dateFormat.format(controller.endsAt.value)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(context, isStart: false),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Obx(
            () => FilledButton(
              onPressed: controller.isSaving.value ? null : controller.save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                minimumSize: const Size.fromHeight(52),
              ),
              child: controller.isSaving.value
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('subscription_save_period'.tr),
            ),
          ),
          if (controller.canCancel) ...[
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => OutlinedButton(
                onPressed: controller.isCancelling.value
                    ? null
                    : controller.cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: controller.isCancelling.value
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('subscription_cancel_action'.tr),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final initial =
        isStart ? controller.startsAt.value : controller.endsAt.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    if (isStart) {
      controller.setStarts(picked);
    } else {
      controller.setEnds(picked);
    }
  }
}
