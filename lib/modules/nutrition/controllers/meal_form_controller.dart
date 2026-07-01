import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';
import 'package:soccer_sys/modules/nutrition/repositories/nutrition_repository.dart';

class MealFormController extends GetxController {
  MealFormController(this._repository, this.args);

  final NutritionRepository _repository;
  final MealFormArgs args;

  late final TextEditingController titleController;
  late final TextEditingController foodItemsController;
  late final TextEditingController caloriesController;
  late final TextEditingController notesController;

  final selectedDayType = NutritionDayType.workout.obs;
  final isSaving = false.obs;
  final pickedPhotoBytes = Rxn<Uint8List>();
  final pickedPhotoName = RxnString();
  final existingPhotoUrl = RxnString();
  final removeExistingPhoto = false.obs;

  final _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final meal = args.meal;
    titleController = TextEditingController(text: meal?.title ?? '');
    foodItemsController = TextEditingController(text: meal?.foodItems ?? '');
    caloriesController =
        TextEditingController(text: meal?.calories.toString() ?? '');
    notesController = TextEditingController(text: meal?.notes ?? '');
    selectedDayType.value = meal?.dayType ?? args.dayType;
    existingPhotoUrl.value = meal?.photoUrl;
  }

  @override
  void onClose() {
    titleController.dispose();
    foodItemsController.dispose();
    caloriesController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    pickedPhotoBytes.value = await file.readAsBytes();
    pickedPhotoName.value = file.name;
    removeExistingPhoto.value = false;
  }

  void clearPhoto() {
    pickedPhotoBytes.value = null;
    pickedPhotoName.value = null;
    existingPhotoUrl.value = null;
    removeExistingPhoto.value = true;
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    final foodItems = foodItemsController.text.trim();
    final calories = int.tryParse(caloriesController.text.trim()) ?? 0;

    if (title.isEmpty) {
      Get.snackbar('', 'nutrition_title_required'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (foodItems.isEmpty) {
      Get.snackbar('', 'nutrition_food_required'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSaving.value = true;
    final notes = notesController.text.trim();

    if (args.isEditing) {
      final draft = args.meal!.copyWith(
        title: title,
        foodItems: foodItems,
        calories: calories,
        notes: notes.isEmpty ? null : notes,
        dayType: selectedDayType.value,
        clearNotes: notes.isEmpty,
      );
      final result = await _repository.updateMeal(
        meal: draft,
        photoBytes: pickedPhotoBytes.value,
        photoFileName: pickedPhotoName.value,
        removePhoto: removeExistingPhoto.value,
      );
      isSaving.value = false;
      if (result.failure != null) {
        Get.snackbar('', result.failure!.message.tr,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
    } else {
      final draft = NutritionMealModel(
        id: '',
        traineeId: args.traineeId,
        trainerId: '',
        dayType: selectedDayType.value,
        title: title,
        foodItems: foodItems,
        calories: calories,
        notes: notes.isEmpty ? null : notes,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _repository.createMeal(
        draft: draft,
        traineeId: args.traineeId,
        dayType: selectedDayType.value,
        photoBytes: pickedPhotoBytes.value,
        photoFileName: pickedPhotoName.value,
      );
      isSaving.value = false;
      if (result.failure != null) {
        Get.snackbar('', result.failure!.message.tr,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    Get.back(result: true);
  }
}
