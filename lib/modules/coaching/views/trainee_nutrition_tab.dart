import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainee_detail_controller.dart';
import 'package:soccer_sys/modules/nutrition/controllers/nutrition_meals_controller.dart';
import 'package:soccer_sys/modules/nutrition/widgets/nutrition_meals_body.dart';

class TraineeNutritionTab extends GetView<NutritionMealsController> {
  const TraineeNutritionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final detailController = Get.find<TraineeDetailController>();

    return Obx(() {
      if (detailController.trainee.value == null) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      return Stack(
        children: [
          const NutritionMealsBody(showHeader: true),
          PositionedDirectional(
            end: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: FloatingActionButton.extended(
              onPressed: controller.openAddMeal,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              icon: const Icon(Icons.add),
              label: Text('nutrition_add_meal'.tr),
            ),
          ),
        ],
      );
    });
  }
}
