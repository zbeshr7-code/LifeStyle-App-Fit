import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:soccer_sys/modules/home/views/trainee/trainee_home_view.dart';
import 'package:soccer_sys/modules/home/views/trainer/trainer_home_view.dart';
import 'package:soccer_sys/modules/workouts/bindings/workout_binding.dart';
import 'package:soccer_sys/modules/home/controllers/trainee_dashboard_controller.dart';
import 'package:soccer_sys/modules/home/controllers/trainer_dashboard_controller.dart';
import 'package:soccer_sys/shared/widgets/shimmer_loading.dart';

class HomeView extends GetView<AuthController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      final isLoadingProfile = controller.isProfileLoading.value;

      if (isLoadingProfile && user == null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: HomeProfileShimmer()),
        );
      }

      if (user == null) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'profile_not_found'.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: controller.loadCurrentProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                      ),
                      child: Text('retry'.tr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      if (user.role == UserRole.trainer) {
        ensureTrainerDashboardController();
        return const TrainerHomeView();
      }

      ensureTraineeWorkoutWeeklyController();
      ensureTraineeDashboardController();
      return const TraineeHomeView();
    });
  }
}
