import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/models/activity_level.dart';
import 'package:soccer_sys/modules/auth/models/gender.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/profile/controllers/profile_controller.dart';
import 'package:soccer_sys/modules/profile/widgets/profile_avatar.dart';
import 'package:soccer_sys/modules/profile/widgets/profile_field_tile.dart';
import 'package:soccer_sys/modules/profile/widgets/profile_info_section.dart';
import 'package:soccer_sys/modules/profile/widgets/profile_subscription_section.dart';
import 'package:soccer_sys/shared/widgets/language_switch.dart';
import 'package:soccer_sys/shared/widgets/theme_switch.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = controller.user.value;
      final isUploading = controller.isUploadingAvatar.value;

      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'nav_profile'.tr,
                          textAlign: TextAlign.start,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: controller.openEdit,
                        icon: Icon(Icons.edit_outlined),
                        color: AppColors.primary,
                        tooltip: 'profile_edit'.tr,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: ProfileAvatar(
                      name: user?.fullName ?? '?',
                      avatarUrl: user?.avatarUrl,
                      onEditTap: controller.showAvatarPicker,
                      isLoading: isUploading,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _IdentityHeader(user: user),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileInfoSection(
                    title: 'profile_section_personal'.tr,
                    children: _personalFields(user),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileInfoSection(
                    title: user?.isTrainer == true
                        ? 'profile_section_trainer'.tr
                        : 'profile_section_trainee'.tr,
                    children: user?.isTrainer == true
                        ? _trainerFields(user)
                        : _traineeFields(user),
                  ),
                  if (user?.isTrainee == true) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ProfileInfoSection(
                      title: 'profile_section_subscription'.tr,
                      children: const [ProfileSubscriptionSection()],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  ProfileInfoSection(
                    title: 'profile_section_preferences'.tr,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          'language'.tr,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                      const LanguageSwitch(),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'theme'.tr,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const ThemeSwitch(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileInfoSection(
                    title: 'profile_section_account'.tr,
                    children: [
                      ProfileFieldTile(
                        label: 'email'.tr,
                        value: user?.email ?? '—',
                      ),
                      ProfileFieldTile(
                        label: 'profile_member_since'.tr,
                        value: user != null
                            ? DateFormat.yMMMd().format(user.createdAt)
                            : '—',
                        isLast: true,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authController.logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceSolid,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text('logout'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  List<Widget> _personalFields(UserModel? user) {
    return [
      ProfileFieldTile(
        label: 'profile_phone'.tr,
        value: user?.phoneNumber ?? '—',
      ),
      ProfileFieldTile(
        label: 'profile_bio'.tr,
        value: user?.bio ?? '—',
      ),
      ProfileFieldTile(
        label: 'profile_gender'.tr,
        value: _genderLabel(user?.gender),
      ),
      ProfileFieldTile(
        label: 'profile_date_of_birth'.tr,
        value: user?.dateOfBirth != null
            ? DateFormat.yMMMd().format(user!.dateOfBirth!)
            : '—',
        isLast: true,
      ),
    ];
  }

  List<Widget> _trainerFields(UserModel? user) {
    return [
      ProfileFieldTile(
        label: 'trainer_specialization'.tr,
        value: user?.specialization ?? '—',
      ),
      ProfileFieldTile(
        label: 'trainer_experience'.tr,
        value: user?.yearsOfExperience != null
            ? '${user!.yearsOfExperience} ${'years'.tr}'
            : '—',
      ),
      ProfileFieldTile(
        label: 'profile_certification'.tr,
        value: user?.certification ?? '—',
      ),
      ProfileFieldTile(
        label: 'profile_hourly_rate'.tr,
        value: user?.hourlyRate != null ? '${user!.hourlyRate}' : '—',
        isLast: true,
      ),
    ];
  }

  List<Widget> _traineeFields(UserModel? user) {
    return [
      Obx(() {
        final trainer = controller.assignedTrainer.value;
        final loading = controller.isLoadingTrainer.value;
        return ProfileFieldTile(
          label: 'coaching_my_trainer'.tr,
          value: loading
              ? '...'
              : trainer?.fullName ?? 'coaching_no_trainer_assigned'.tr,
          onTap: controller.openChooseTrainer,
        );
      }),
      ProfileFieldTile(
        label: 'trainee_fitness_goal'.tr,
        value: user?.fitnessGoal ?? 'trainee_no_goal_set'.tr,
      ),
      ProfileFieldTile(
        label: 'trainee_height'.tr,
        value: user?.heightCm != null ? '${user!.heightCm} cm' : '—',
      ),
      ProfileFieldTile(
        label: 'trainee_current_weight'.tr,
        value: user?.currentWeight != null ? '${user!.currentWeight} kg' : '—',
      ),
      ProfileFieldTile(
        label: 'trainee_target_weight'.tr,
        value: user?.targetWeight != null ? '${user!.targetWeight} kg' : '—',
      ),
      ProfileFieldTile(
        label: 'trainee_activity'.tr,
        value: _activityLabel(user?.activityLevel),
      ),
      ProfileFieldTile(
        label: 'activity_daily_goal'.tr,
        value: '${user?.dailyStepGoal ?? 10000}',
        isLast: true,
      ),
    ];
  }

  String _genderLabel(Gender? gender) {
    if (gender == null) return '—';
    return switch (gender) {
      Gender.male => 'gender_male'.tr,
      Gender.female => 'gender_female'.tr,
    };
  }

  String _activityLabel(ActivityLevel? level) {
    if (level == null) return '—';
    return switch (level) {
      ActivityLevel.sedentary => 'activity_level_sedentary'.tr,
      ActivityLevel.light => 'activity_level_light'.tr,
      ActivityLevel.moderate => 'activity_level_moderate'.tr,
      ActivityLevel.active => 'activity_level_active'.tr,
      ActivityLevel.veryActive => 'activity_level_very_active'.tr,
    };
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          user?.fullName ?? '—',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _Chip(
              label: user?.isTrainer == true
                  ? 'role_trainer'.tr
                  : 'role_trainee'.tr,
              color: AppColors.primary,
            ),
            if (user?.isVerified == true)
              _Chip(
                label: 'profile_verified'.tr,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
