import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/workouts/controllers/exercise_form_controller.dart';

class ExerciseFormView extends GetView<ExerciseFormController> {
  const ExerciseFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          controller.args.isEditing
              ? 'workout_edit_exercise'.tr
              : 'workout_add_exercise'.tr,
        ),
      ),
      body: Obx(() {
        final saving = controller.isSaving.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller.nameController,
                enabled: !saving,
                decoration: InputDecoration(
                  labelText: 'workout_exercise_name'.tr,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.setsController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'workout_sets'.tr,
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: controller.repsController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'workout_reps'.tr,
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller.weightController,
                enabled: !saving,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'workout_target_weight'.tr,
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
                controller: controller.videoUrlController,
                enabled: !saving,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'workout_video_url'.tr,
                  hintText: 'workout_video_url_hint'.tr,
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
                  labelText: 'workout_notes'.tr,
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
                'workout_photo'.tr,
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

  final ExerciseFormController controller;
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
              child: Image.memory(bytes, height: 140, fit: BoxFit.cover),
            )
          else if (url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: CachedNetworkImage(
                imageUrl: url,
                height: 140,
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
