import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/trainer_plan_form_controller.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_enums.dart';

class TrainerPlanFormView extends GetView<TrainerPlanFormController> {
  const TrainerPlanFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          controller.isEditing
              ? 'subscription_edit_plan'.tr
              : 'subscription_add_plan'.tr,
        ),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        children: [
          TextField(
            controller: controller.titleController,
            decoration: InputDecoration(
              labelText: 'subscription_field_title'.tr,
              filled: true,
              fillColor: AppColors.inputFill,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller.descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'subscription_field_description'.tr,
              filled: true,
              fillColor: AppColors.inputFill,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller.priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'subscription_field_price'.tr,
              suffixText: 'subscription_currency_sar'.tr,
              filled: true,
              fillColor: AppColors.inputFill,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'subscription_field_duration'.tr,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text('subscription_duration_1_month'.tr),
                  selected:
                      controller.durationPreset.value == PlanDurationPreset.oneMonth,
                  onSelected: (_) =>
                      controller.setPreset(PlanDurationPreset.oneMonth),
                ),
                ChoiceChip(
                  label: Text('subscription_duration_3_months'.tr),
                  selected: controller.durationPreset.value ==
                      PlanDurationPreset.threeMonths,
                  onSelected: (_) =>
                      controller.setPreset(PlanDurationPreset.threeMonths),
                ),
                ChoiceChip(
                  label: Text('subscription_duration_custom'.tr),
                  selected:
                      controller.durationPreset.value == PlanDurationPreset.custom,
                  onSelected: (_) =>
                      controller.setPreset(PlanDurationPreset.custom),
                ),
              ],
            ),
          ),
          Obx(
            () => controller.durationPreset.value == PlanDurationPreset.custom
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                    child: TextField(
                      controller: controller.customDaysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'subscription_field_custom_days'.tr,
                        filled: true,
                        fillColor: AppColors.inputFill,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => SwitchListTile(
              value: controller.isFeatured.value,
              onChanged: (v) => controller.isFeatured.value = v,
              title: Text('subscription_field_featured'.tr),
              activeThumbColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'subscription_field_features'.tr,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => controller.featureInput.value = v,
                  onSubmitted: (_) => controller.addFeature(),
                  decoration: InputDecoration(
                    hintText: 'subscription_feature_hint'.tr,
                    filled: true,
                    fillColor: AppColors.inputFill,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.addFeature,
                icon: Icon(Icons.add_circle, color: AppColors.primary),
              ),
            ],
          ),
          Obx(
            () => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: List.generate(controller.features.length, (i) {
                return Chip(
                  label: Text(controller.features[i]),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => controller.removeFeature(i),
                );
              }),
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
                  : Text('subscription_save_plan'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
