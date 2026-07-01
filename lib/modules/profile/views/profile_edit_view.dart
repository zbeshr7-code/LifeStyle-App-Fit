import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/models/activity_level.dart';
import 'package:soccer_sys/modules/auth/models/gender.dart';
import 'package:soccer_sys/modules/profile/controllers/profile_edit_controller.dart';
import 'package:soccer_sys/shared/widgets/auth_widgets.dart';

class ProfileEditView extends GetView<ProfileEditController> {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('profile_edit'.tr),
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.isSaving.value ? null : () => controller.save(),
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
                  AppTextField(
                    label: 'profile_first_name'.tr,
                    controller: controller.firstNameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'validation_name_required'.tr
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'profile_last_name'.tr,
                    controller: controller.lastNameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'validation_name_required'.tr
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ReadOnlyField(
                    label: 'email'.tr,
                    value: user?.email ?? '—',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ReadOnlyField(
                    label: 'role'.tr,
                    value: user?.isTrainer == true
                        ? 'role_trainer'.tr
                        : 'role_trainee'.tr,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'profile_section_personal'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'profile_phone'.tr,
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'profile_bio'.tr,
                    controller: controller.bioController,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GenderDropdown(controller: controller),
                  const SizedBox(height: AppSpacing.md),
                  _DateOfBirthField(controller: controller),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    controller.isTrainer
                        ? 'profile_section_trainer'.tr
                        : 'profile_section_trainee'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (controller.isTrainer) ...[
                    AppTextField(
                      label: 'trainer_specialization'.tr,
                      controller: controller.specializationController,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'trainer_experience'.tr,
                      controller: controller.experienceController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'profile_certification'.tr,
                      controller: controller.certificationController,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'profile_hourly_rate'.tr,
                      controller: controller.hourlyRateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ] else ...[
                    AppTextField(
                      label: 'trainee_fitness_goal'.tr,
                      controller: controller.fitnessGoalController,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'trainee_height'.tr,
                      controller: controller.heightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'trainee_current_weight'.tr,
                      controller: controller.currentWeightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'trainee_target_weight'.tr,
                      controller: controller.targetWeightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ActivityDropdown(controller: controller),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'activity_daily_goal'.tr,
                      controller: controller.stepGoalController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
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

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: value,
          readOnly: true,
          enabled: false,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.controller});

  final ProfileEditController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'profile_gender'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<Gender>(
            initialValue: controller.selectedGender.value,
            decoration: const InputDecoration(),
            items: Gender.values
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(
                      g == Gender.male
                          ? 'gender_male'.tr
                          : 'gender_female'.tr,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => controller.selectedGender.value = v,
          ),
        ],
      ),
    );
  }
}

class _ActivityDropdown extends StatelessWidget {
  const _ActivityDropdown({required this.controller});

  final ProfileEditController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'trainee_activity'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<ActivityLevel>(
            initialValue: controller.selectedActivityLevel.value,
            decoration: const InputDecoration(),
            items: ActivityLevel.values
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(_activityLabel(level)),
                  ),
                )
                .toList(),
            onChanged: (v) => controller.selectedActivityLevel.value = v,
          ),
        ],
      ),
    );
  }

  String _activityLabel(ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => 'activity_level_sedentary'.tr,
      ActivityLevel.light => 'activity_level_light'.tr,
      ActivityLevel.moderate => 'activity_level_moderate'.tr,
      ActivityLevel.active => 'activity_level_active'.tr,
      ActivityLevel.veryActive => 'activity_level_very_active'.tr,
    };
  }
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({required this.controller});

  final ProfileEditController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InkWell(
        onTap: () => controller.pickDateOfBirth(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'profile_date_of_birth'.tr,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            controller.dateOfBirth.value != null
                ? DateFormat.yMMMd().format(controller.dateOfBirth.value!)
                : 'profile_pick_date'.tr,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
