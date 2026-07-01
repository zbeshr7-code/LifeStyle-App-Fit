import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:soccer_sys/core/routes/app_routes.dart';

import 'package:soccer_sys/core/theme/tokens.dart';

import 'package:soccer_sys/modules/auth/models/user_model.dart';

import 'package:soccer_sys/modules/chat/controllers/chat_controller.dart';

import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';

import 'package:soccer_sys/modules/coaching/controllers/trainer_clients_controller.dart';

import 'package:soccer_sys/modules/coaching/models/trainee_detail_args.dart';

import 'package:soccer_sys/shared/widgets/glass_container.dart';



class TrainerClientsTab extends GetView<TrainerClientsController> {

  const TrainerClientsTab({super.key});



  static String _initials(String name) {

    final trimmed = name.trim();

    if (trimmed.isEmpty) return '?';

    return trimmed[0].toUpperCase();

  }



  static String _subtitle(UserModel trainee) {

    final goal = trainee.fitnessGoal?.trim();

    if (goal != null && goal.isNotEmpty) return goal;

    return 'trainer_client_active'.tr;

  }



  void _openTraineeDetail(UserModel trainee) {

    Get.toNamed(

      AppRoutes.traineeDetail,

      arguments: TraineeDetailArgs(trainee: trainee),

    );

  }



  @override

  Widget build(BuildContext context) {

    final chatController = Get.find<ChatController>();



    return RefreshIndicator(

      color: AppColors.primary,

      onRefresh: controller.loadTrainees,

      child: CustomScrollView(

        physics: const AlwaysScrollableScrollPhysics(),

        slivers: [

          SliverPadding(

            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),

            sliver: SliverToBoxAdapter(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  Text(

                    'nav_clients'.tr,

                    textAlign: TextAlign.start,

                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                          fontWeight: FontWeight.bold,

                        ),

                  ),

                  SizedBox(height: AppSpacing.sm),

                  Text(

                    'trainer_clients_subtitle'.tr,

                    textAlign: TextAlign.start,

                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                          color: AppColors.textSecondary,

                        ),

                  ),

                  const SizedBox(height: AppSpacing.md),

                  GlassContainer(

                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),

                    child: Text(

                      'coaching_trainer_clients_hint'.tr,

                      style: Theme.of(context).textTheme.bodySmall?.copyWith(

                            color: AppColors.textSecondary,

                          ),

                    ),

                  ),

                ],

              ),

            ),

          ),

          Obx(() {

            if (controller.status.value.isLoading &&

                controller.trainees.isEmpty) {

              return  SliverFillRemaining(

                child: Center(

                  child: CircularProgressIndicator(color: AppColors.primary),

                ),

              );

            }



            if (controller.status.value.isError &&

                controller.trainees.isEmpty) {

              return SliverFillRemaining(

                child: Center(

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

                        onPressed: controller.loadTrainees,

                        child: Text('retry'.tr),

                      ),

                    ],

                  ),

                ),

              );

            }



            if (controller.trainees.isEmpty) {

              return SliverFillRemaining(

                hasScrollBody: false,

                child: Center(

                  child: Text(

                    'coaching_no_clients'.tr,

                    style:  TextStyle(color: AppColors.textSecondary),

                    textAlign: TextAlign.center,

                  ),

                ),

              );

            }



            return SliverPadding(

              padding: const EdgeInsetsDirectional.symmetric(

                horizontal: AppSpacing.lg,

              ),

              sliver: SliverList.separated(

                itemCount: controller.trainees.length,

                separatorBuilder: (_, __) =>

                    const SizedBox(height: AppSpacing.sm),

                itemBuilder: (context, index) {

                  final trainee = controller.trainees[index];

                  return _ClientTile(

                    trainee: trainee,

                    initials: _initials(trainee.fullName),

                    subtitle: _subtitle(trainee),

                    onTap: () => _openTraineeDetail(trainee),

                    onChat: () => chatController.startChatWithPeer(

                      ChatPeerModel.fromUser(trainee),

                      popSheet: false,

                    ),

                  );

                },

              ),

            );

          }),

          const SliverPadding(padding: EdgeInsetsDirectional.only(bottom: 24)),

        ],

      ),

    );

  }

}



class _ClientTile extends StatelessWidget {

  const _ClientTile({

    required this.trainee,

    required this.initials,

    required this.subtitle,

    required this.onTap,

    required this.onChat,

  });



  final UserModel trainee;

  final String initials;

  final String subtitle;

  final VoidCallback onTap;

  final VoidCallback onChat;



  @override

  Widget build(BuildContext context) {

    return GlassContainer(

      padding: const EdgeInsetsDirectional.all(AppSpacing.md),

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(AppRadius.lg),

        child: Row(

          children: [

            CircleAvatar(

              backgroundColor: AppColors.primary.withValues(alpha: 0.2),

              backgroundImage: trainee.avatarUrl != null

                  ? NetworkImage(trainee.avatarUrl!)

                  : null,

              child: trainee.avatarUrl == null

                  ? Text(

                      initials,

                      style:  TextStyle(

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

                    trainee.fullName,

                    textAlign: TextAlign.start,

                    style: Theme.of(context).textTheme.titleSmall?.copyWith(

                          fontWeight: FontWeight.w600,

                        ),

                  ),

                  Text(

                    subtitle,

                    textAlign: TextAlign.start,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: Theme.of(context).textTheme.bodySmall?.copyWith(

                          color: AppColors.textSecondary,

                        ),

                  ),

                ],

              ),

            ),

            IconButton(

              onPressed: onChat,

              icon: Icon(

                Icons.chat_bubble_outline,

                color: AppColors.primary.withValues(alpha: 0.9),

              ),

            ),

             Icon(Icons.chevron_right, color: AppColors.textSecondary),

          ],

        ),

      ),

    );

  }

}

