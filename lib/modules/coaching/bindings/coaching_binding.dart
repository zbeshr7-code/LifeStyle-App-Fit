import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/activity/bindings/activity_binding.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/repositories/activity_repository.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/chat/bindings/chat_binding.dart';
import 'package:soccer_sys/modules/coaching/controllers/choose_trainer_controller.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainee_activity_controller.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainee_activity_history_controller.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainee_detail_controller.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainer_clients_controller.dart';
import 'package:soccer_sys/modules/coaching/models/trainee_detail_args.dart';
import 'package:soccer_sys/modules/coaching/repositories/coaching_repository.dart';
import 'package:soccer_sys/modules/coaching/services/coaching_service.dart';
import 'package:soccer_sys/modules/nutrition/bindings/nutrition_binding.dart';
import 'package:soccer_sys/modules/workouts/bindings/workout_binding.dart';

class CoachingBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    Get.lazyPut<CoachingService>(
      () => CoachingService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<CoachingRepository>(
      () => CoachingRepository(Get.find<CoachingService>()),
      fenix: true,
    );
  }
}

class ChooseTrainerBinding extends Bindings {
  @override
  void dependencies() {
    CoachingBinding().dependencies();
    Get.lazyPut<ChooseTrainerController>(
      () => ChooseTrainerController(
        Get.find<CoachingRepository>(),
        Get.find<AuthController>(),
      ),
    );
  }
}

class TrainerClientsBinding extends Bindings {
  @override
  void dependencies() {
    CoachingBinding().dependencies();
    if (!Get.isRegistered<TrainerClientsController>()) {
      Get.put<TrainerClientsController>(
        TrainerClientsController(Get.find<CoachingRepository>()),
        permanent: true,
      );
    }
  }
}

class TraineeDetailBinding extends Bindings {
  @override
  void dependencies() {
    CoachingBinding().dependencies();
    ActivityBinding().dependencies();
    ChatBinding().dependencies();
    NutritionBinding().dependencies();

    final args = Get.arguments as TraineeDetailArgs;

    Get.lazyPut<TraineeDetailController>(
      () => TraineeDetailController(Get.find<CoachingRepository>()),
    );
    Get.lazyPut<TraineeActivityController>(
      () => TraineeActivityController(
        Get.find<ActivityRepository>(),
        Get.find<TraineeDetailController>(),
      ),
    );
    TrainerTraineeNutritionBinding(args.trainee.id).dependencies();
    TrainerTraineeWorkoutBinding(args.trainee.id).dependencies();
  }
}

class TraineeActivityHistoryBinding extends Bindings {
  @override
  void dependencies() {
    ActivityBinding().dependencies();
    final args = Get.arguments as TraineeActivityHistoryArgs;
    Get.lazyPut<TraineeActivityHistoryController>(
      () => TraineeActivityHistoryController(
        Get.find<ActivityRepository>(),
        args.traineeContext,
      ),
    );
  }
}
