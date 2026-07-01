import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/models/activity_level.dart';
import 'package:soccer_sys/modules/auth/models/gender.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/chat/controllers/chat_controller.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainee_detail_controller.dart';
import 'package:soccer_sys/modules/coaching/views/trainee_activity_tab.dart';
import 'package:soccer_sys/modules/coaching/views/trainee_nutrition_tab.dart';
import 'package:soccer_sys/modules/coaching/views/trainee_workout_tab.dart';
import 'package:soccer_sys/modules/profile/widgets/profile_avatar.dart';
import 'package:soccer_sys/modules/profile/widgets/profile_field_tile.dart';
import 'package:soccer_sys/modules/profile/widgets/profile_info_section.dart';

class TraineeDetailView extends GetView<TraineeDetailController> {
  const TraineeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Obx(() {
            final name = controller.trainee.value?.fullName;
            return Text(
              name ?? 'trainer_client_detail_title'.tr,
            );
          }),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'trainer_client_tab_profile'.tr),
              Tab(text: 'trainer_client_tab_tracking'.tr),
              Tab(text: 'trainer_client_tab_nutrition'.tr),
              Tab(text: 'trainer_client_tab_workouts'.tr),
            ],
          ),
        ),
        body: Obx(() {
          final user = controller.trainee.value;
          final isLoading =
              controller.status.value.isLoading && user == null;

          if (isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.errorMessage.value.isNotEmpty
                        ? controller.errorMessage.value
                        : 'profile_not_found'.tr,
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: controller.refreshTrainee,
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            children: [
              _TraineeProfileTab(user: user),
              const TraineeActivityTab(),
              const TraineeNutritionTab(),
              const TraineeWorkoutTab(),
            ],
          );
        }),
      ),
    );
  }
}

class _TraineeProfileTab extends StatelessWidget {
  const _TraineeProfileTab({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final detailController = Get.find<TraineeDetailController>();
    final chatController = Get.find<ChatController>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: detailController.refreshTrainee,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ProfileAvatar(
                      name: user.fullName,
                      avatarUrl: user.avatarUrl,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _IdentityHeader(user: user),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => chatController.startChatWithPeer(
                        ChatPeerModel.fromUser(user),
                        popSheet: false,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text('trainer_client_chat'.tr),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileInfoSection(
                    title: 'profile_section_personal'.tr,
                    children: _personalFields(user),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileInfoSection(
                    title: 'profile_section_trainee'.tr,
                    children: _traineeFields(user),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileInfoSection(
                    title: 'profile_section_account'.tr,
                    children: [
                      ProfileFieldTile(
                        label: 'email'.tr,
                        value: user.email,
                      ),
                      ProfileFieldTile(
                        label: 'profile_member_since'.tr,
                        value: DateFormat.yMMMd().format(user.createdAt),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _personalFields(UserModel user) {
    return [
      ProfileFieldTile(
        label: 'profile_phone'.tr,
        value: user.phoneNumber ?? '—',
      ),
      ProfileFieldTile(
        label: 'profile_bio'.tr,
        value: user.bio ?? '—',
      ),
      ProfileFieldTile(
        label: 'profile_gender'.tr,
        value: _genderLabel(user.gender),
      ),
      ProfileFieldTile(
        label: 'profile_date_of_birth'.tr,
        value: user.dateOfBirth != null
            ? DateFormat.yMMMd().format(user.dateOfBirth!)
            : '—',
        isLast: true,
      ),
    ];
  }

  List<Widget> _traineeFields(UserModel user) {
    return [
      ProfileFieldTile(
        label: 'trainee_fitness_goal'.tr,
        value: user.fitnessGoal ?? 'trainee_no_goal_set'.tr,
      ),
      ProfileFieldTile(
        label: 'trainee_height'.tr,
        value: user.heightCm != null ? '${user.heightCm} cm' : '—',
      ),
      ProfileFieldTile(
        label: 'trainee_current_weight'.tr,
        value: user.currentWeight != null ? '${user.currentWeight} kg' : '—',
      ),
      ProfileFieldTile(
        label: 'trainee_target_weight'.tr,
        value: user.targetWeight != null ? '${user.targetWeight} kg' : '—',
      ),
      ProfileFieldTile(
        label: 'trainee_activity'.tr,
        value: _activityLabel(user.activityLevel),
      ),
      ProfileFieldTile(
        label: 'activity_daily_goal'.tr,
        value: '${user.dailyStepGoal}',
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

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          user.fullName,
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
            _Chip(label: 'role_trainee'.tr, color: AppColors.primary),
            if (user.isVerified)
              _Chip(
                label: 'profile_verified'.tr,
                color: AppColors.textSecondary,
              ),
            _Chip(
              label: 'trainer_client_active'.tr,
              color: AppColors.primary,
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
