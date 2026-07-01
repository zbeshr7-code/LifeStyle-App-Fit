import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';
import 'package:soccer_sys/modules/nutrition/repositories/nutrition_repository.dart';

class NutritionMealsController extends GetxController {
  NutritionMealsController(
    this._repository, {
    required this.traineeId,
    this.canManage = false,
  });

  final NutritionRepository _repository;
  final String traineeId;
  final bool canManage;

  final selectedDayType = NutritionDayType.workout.obs;
  final meals = <NutritionMealModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final isSavingOrder = false.obs;

  int get totalCalories =>
      meals.fold(0, (sum, meal) => sum + meal.calories);

  @override
  void onInit() {
    super.onInit();
    ever(selectedDayType, (_) => loadMeals());
    loadMeals();
  }

  void selectDayType(NutritionDayType type) {
    selectedDayType.value = type;
  }

  Future<void> loadMeals() async {
    status.value = RxStatus.loading();
    final result = await _repository.fetchMeals(
      traineeId: traineeId,
      dayType: selectedDayType.value,
    );
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    meals.assignAll(result.meals);
    status.value = RxStatus.success();
  }

  Future<void> reorderMeals(int oldIndex, int newIndex) async {
    if (!canManage) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = List<NutritionMealModel>.from(meals);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    meals.assignAll(updated);

    isSavingOrder.value = true;
    final failure = await _repository.reorderMeals(
      traineeId: traineeId,
      dayType: selectedDayType.value,
      meals: updated,
    );
    isSavingOrder.value = false;
    if (failure != null) {
      Get.snackbar('', failure.message.tr, snackPosition: SnackPosition.BOTTOM);
      await loadMeals();
    }
  }

  Future<void> deleteMeal(NutritionMealModel meal) async {
    if (!canManage) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('nutrition_delete_title'.tr),
        content: Text('nutrition_delete_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('chat_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'nutrition_delete_confirm'.tr,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    status.value = RxStatus.loading();
    final failure = await _repository.deleteMeal(meal);
    if (failure != null) {
      errorMessage.value = failure.message.tr;
      status.value = RxStatus.error(failure.message.tr);
      return;
    }
    await loadMeals();
  }

  void openAddMeal() {
    if (!canManage) return;
    Get.toNamed(
      AppRoutes.nutritionMealForm,
      arguments: MealFormArgs(
        traineeId: traineeId,
        dayType: selectedDayType.value,
      ),
    )?.then((_) => loadMeals());
  }

  void openEditMeal(NutritionMealModel meal) {
    if (!canManage) return;
    Get.toNamed(
      AppRoutes.nutritionMealForm,
      arguments: MealFormArgs(
        traineeId: traineeId,
        dayType: selectedDayType.value,
        meal: meal,
      ),
    )?.then((_) => loadMeals());
  }
}
