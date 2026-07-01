import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/nutrition/controllers/nutrition_meals_controller.dart';
import 'package:soccer_sys/modules/nutrition/widgets/nutrition_meals_body.dart';

class NutritionMealsView extends GetView<NutritionMealsController> {
  const NutritionMealsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('nutrition_title'.tr),
      ),
      body: const SafeArea(child: NutritionMealsBody()),
    );
  }
}
