import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/coaching/controllers/choose_trainer_controller.dart';

class ChooseTrainerView extends GetView<ChooseTrainerController> {
  const ChooseTrainerView({super.key});

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('coaching_choose_trainer_title'.tr),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Text(
              'coaching_choose_trainer_subtitle'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: 'chat_search'.tr,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Obx(() {
              if (controller.status.value.isLoading &&
                  controller.trainers.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (controller.status.value.isError &&
                  controller.trainers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.errorMessage.value,
                        style: TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: controller.loadTrainers,
                        child: Text('retry'.tr),
                      ),
                    ],
                  ),
                );
              }

              final list = controller.filteredTrainers;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'coaching_no_trainers'.tr,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final trainer = list[index];
                  return _TrainerTile(
                    trainer: trainer,
                    initials: _initials(trainer.fullName),
                    onTap: () => controller.selectTrainer(trainer),
                    isSaving: controller.isSaving.value,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TrainerTile extends StatelessWidget {
  const _TrainerTile({
    required this.trainer,
    required this.initials,
    required this.onTap,
    required this.isSaving,
  });

  final ChatPeerModel trainer;
  final String initials;
  final VoidCallback onTap;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSolid,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: trainer.avatarUrl != null
                    ? NetworkImage(trainer.avatarUrl!)
                    : null,
                child: trainer.avatarUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      trainer.fullName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (trainer.role.name.isNotEmpty)
                      Text(
                        'role_trainer'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
