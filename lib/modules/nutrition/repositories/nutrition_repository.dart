import 'dart:typed_data';

import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';
import 'package:soccer_sys/modules/nutrition/services/nutrition_service.dart';
import 'package:soccer_sys/modules/nutrition/services/nutrition_storage_service.dart';

class NutritionRepository {
  NutritionRepository(this._nutritionService, this._storageService);

  final NutritionService _nutritionService;
  final NutritionStorageService _storageService;

  Future<({Failure? failure, List<NutritionMealModel> meals})> fetchMeals({
    required String traineeId,
    required NutritionDayType dayType,
  }) async {
    try {
      final data = await _nutritionService.fetchMeals(
        traineeId: traineeId,
        dayType: dayType,
      );
      final meals = await _attachPhotoUrls(
        data.map(NutritionMealModel.fromJson).toList(),
      );
      return (failure: null, meals: meals);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        meals: <NutritionMealModel>[],
      );
    }
  }

  Future<({Failure? failure, NutritionMealModel? meal})> createMeal({
    required NutritionMealModel draft,
    required String traineeId,
    required NutritionDayType dayType,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    try {
      final trainerId = _nutritionService.currentUserId;
      if (trainerId == null) throw Exception('Not authenticated');

      final sortOrder = await _nutritionService.nextSortOrder(
        traineeId: traineeId,
        dayType: dayType,
      );

      final created = await _nutritionService.createMeal(
        draft.toInsertJson(
          traineeId: traineeId,
          trainerId: trainerId,
          dayType: dayType,
          sortOrder: sortOrder,
        ),
      );

      var meal = NutritionMealModel.fromJson(created);
      if (photoBytes != null) {
        final path = await _storageService.uploadPhoto(
          traineeId: traineeId,
          mealId: meal.id,
          bytes: photoBytes,
          fileName: photoFileName ?? 'meal.jpg',
        );
        final updated = await _nutritionService.updateMeal(
          meal.id,
          {'photo_path': path},
        );
        meal = NutritionMealModel.fromJson(updated);
      }

      final withUrl = await _attachPhotoUrls([meal]);
      return (failure: null, meal: withUrl.first);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), meal: null);
    }
  }

  Future<({Failure? failure, NutritionMealModel? meal})> updateMeal({
    required NutritionMealModel meal,
    Uint8List? photoBytes,
    String? photoFileName,
    bool removePhoto = false,
  }) async {
    try {
      var photoPath = meal.photoPath;
      if (removePhoto && photoPath != null) {
        await _storageService.deletePath(photoPath);
        photoPath = null;
      } else if (photoBytes != null) {
        photoPath = await _storageService.uploadPhoto(
          traineeId: meal.traineeId,
          mealId: meal.id,
          bytes: photoBytes,
          fileName: photoFileName ?? 'meal.jpg',
        );
      }

      final payload = meal.copyWith(photoPath: photoPath).toUpdateJson();
      if (removePhoto) payload['photo_path'] = null;

      final updated = await _nutritionService.updateMeal(meal.id, payload);
      final result = await _attachPhotoUrls([
        NutritionMealModel.fromJson(updated),
      ]);
      return (failure: null, meal: result.first);
    } catch (error) {
      return (failure: FailureMapper.fromException(error), meal: null);
    }
  }

  Future<Failure?> deleteMeal(NutritionMealModel meal) async {
    try {
      await _storageService.deletePath(meal.photoPath);
      await _nutritionService.deleteMeal(meal.id);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<Failure?> reorderMeals({
    required String traineeId,
    required NutritionDayType dayType,
    required List<NutritionMealModel> meals,
  }) async {
    try {
      await _nutritionService.reorderMeals(
        traineeId: traineeId,
        dayType: dayType,
        mealIds: meals.map((m) => m.id).toList(),
      );
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<List<NutritionMealModel>> _attachPhotoUrls(
    List<NutritionMealModel> meals,
  ) async {
    final result = <NutritionMealModel>[];
    for (final meal in meals) {
      if (meal.photoPath == null || meal.photoPath!.isEmpty) {
        result.add(meal);
        continue;
      }
      final url = await _storageService.resolveUrl(meal.photoPath!);
      result.add(meal.copyWith(photoUrl: url));
    }
    return result;
  }
}
