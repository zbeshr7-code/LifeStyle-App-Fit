import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/nutrition/controllers/meal_form_controller.dart';
import 'package:soccer_sys/modules/nutrition/controllers/nutrition_meals_controller.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';
import 'package:soccer_sys/modules/nutrition/repositories/nutrition_repository.dart';
import 'package:soccer_sys/modules/nutrition/services/nutrition_service.dart';
import 'package:soccer_sys/modules/nutrition/services/nutrition_storage_service.dart';

class NutritionBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    Get.lazyPut<NutritionService>(
      () => NutritionService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<NutritionStorageService>(
      () => NutritionStorageService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<NutritionRepository>(
      () => NutritionRepository(
        Get.find<NutritionService>(),
        Get.find<NutritionStorageService>(),
      ),
      fenix: true,
    );
  }
}

class TraineeNutritionBinding extends Bindings {
  @override
  void dependencies() {
    NutritionBinding().dependencies();
    final auth = Get.find<AuthController>();
    final traineeId = auth.currentUser.value?.id;
    if (traineeId == null) return;

    Get.lazyPut<NutritionMealsController>(
      () => NutritionMealsController(
        Get.find<NutritionRepository>(),
        traineeId: traineeId,
      ),
    );
  }
}

class TrainerTraineeNutritionBinding extends Bindings {
  TrainerTraineeNutritionBinding(this.traineeId);

  final String traineeId;

  @override
  void dependencies() {
    NutritionBinding().dependencies();
    if (Get.isRegistered<NutritionMealsController>()) {
      Get.delete<NutritionMealsController>();
    }
    Get.put<NutritionMealsController>(
      NutritionMealsController(
        Get.find<NutritionRepository>(),
        traineeId: traineeId,
        canManage: true,
      ),
    );
  }
}

class MealFormBinding extends Bindings {
  @override
  void dependencies() {
    NutritionBinding().dependencies();
    final args = Get.arguments as MealFormArgs;
    Get.lazyPut<MealFormController>(
      () => MealFormController(Get.find<NutritionRepository>(), args),
    );
  }
}
