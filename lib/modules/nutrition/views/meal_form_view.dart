import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/nutrition/controllers/meal_form_controller.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';

class MealFormView extends GetView<MealFormController> {
  const MealFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          controller.args.isEditing
              ? 'nutrition_edit_meal'.tr
              : 'nutrition_add_meal'.tr,
        ),
      ),
      body: Obx(() {
        final saving = controller.isSaving.value;
        return SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'nutrition_day_type'.tr,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<NutritionDayType>(
                segments: [
                  ButtonSegment(
                    value: NutritionDayType.workout,
                    label: Text('nutrition_day_workout'.tr),
                    icon: const Icon(Icons.fitness_center, size: 18),
                  ),
                  ButtonSegment(
                    value: NutritionDayType.rest,
                    label: Text('nutrition_day_rest'.tr),
                    icon: const Icon(Icons.hotel, size: 18),
                  ),
                ],
                selected: {controller.selectedDayType.value},
                onSelectionChanged: saving
                    ? null
                    : (value) =>
                        controller.selectedDayType.value = value.first,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller.titleController,
                enabled: !saving,
                decoration: InputDecoration(
                  labelText: 'nutrition_meal_title'.tr,
                  hintText: 'nutrition_meal_title_hint'.tr,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller.foodItemsController,
                enabled: !saving,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'nutrition_food_items'.tr,
                  hintText: 'nutrition_food_items_hint'.tr,
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller.caloriesController,
                enabled: !saving,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'activity_calories'.tr,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller.notesController,
                enabled: !saving,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'nutrition_notes'.tr,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'nutrition_photo'.tr,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              _PhotoPicker(controller: controller, saving: saving),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: saving ? null : controller.save,
                  child: saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('profile_save'.tr),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.controller, required this.saving});

  final MealFormController controller;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bytes = controller.pickedPhotoBytes.value;
      final url = controller.existingPhotoUrl.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.memory(bytes, height: 160, fit: BoxFit.cover),
            )
          else if (url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: CachedNetworkImage(
                imageUrl: url,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () => controller.pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text('nutrition_pick_photo'.tr),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () => controller.pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text('nutrition_take_photo'.tr),
                ),
              ),
            ],
          ),
          if (bytes != null || url != null)
            TextButton(
              onPressed: saving ? null : controller.clearPhoto,
              child: Text(
                'nutrition_remove_photo'.tr,
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      );
    });
  }
}
