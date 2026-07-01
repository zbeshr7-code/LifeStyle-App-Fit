import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/progress/controllers/progress_entry_controller.dart';
import 'package:soccer_sys/shared/widgets/auth_widgets.dart';

class AddProgressEntryView extends GetView<ProgressEntryController> {
  const AddProgressEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('progress_add_entry'.tr),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isSaving.value ? null : controller.save,
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'profile_save'.tr,
                      style: TextStyle(color: AppColors.primary),
                    ),
            ),
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            Form(
              key: controller.formKey,
              child: ListView(
                padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                children: [
                  Obx(
                    () => InkWell(
                      onTap: () => controller.pickDate(context),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'progress_recorded_date'.tr,
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(controller.recordedAt.value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'trainee_current_weight'.tr,
                    controller: controller.weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'progress_note'.tr,
                    controller: controller.noteController,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'progress_photos_label'.tr,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: controller.pickPhotos,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text('progress_pick_photos'.tr),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (controller.pickedPhotos.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.pickedPhotos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                child: Image.memory(
                                  controller.pickedPhotos[index].bytes,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              PositionedDirectional(
                                top: 4,
                                end: 4,
                                child: GestureDetector(
                                  onTap: () => controller.removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (controller.isSaving.value)
              const ColoredBox(
                color: Color(0x44000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
