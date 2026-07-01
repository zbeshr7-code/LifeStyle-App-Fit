import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_assign_subscription_controller.dart';
import 'package:soccer_sys/shared/widgets/glass_container.dart';

class TrainerAssignSubscriptionView
    extends GetView<TrainerAssignSubscriptionController> {
  const TrainerAssignSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('subscription_assign_title'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.trainees.isEmpty) {
          return Center(child: Text('subscription_assign_no_trainees'.tr));
        }
        if (controller.plans.isEmpty) {
          return Center(child: Text('subscription_trainer_no_plans'.tr));
        }

        return ListView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          children: [
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'subscription_assign_trainee'.tr,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: controller.selectedTraineeId.value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    items: controller.trainees
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        controller.selectedTraineeId.value = value,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'subscription_assign_plan'.tr,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: controller.selectedPlanId.value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    items: controller.plans
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.title),
                          ),
                        )
                        .toList(),
                    onChanged: controller.onPlanChanged,
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
            const SizedBox(height: AppSpacing.xl),
            Obx(
              () => FilledButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.assign,
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
                    : Text('subscription_assign_activate'.tr),
              ),
            ),
          ],
        );
      }),
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
