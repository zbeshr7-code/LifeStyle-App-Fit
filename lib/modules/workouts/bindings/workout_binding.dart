import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/workouts/controllers/exercise_form_controller.dart';
import 'package:soccer_sys/modules/workouts/controllers/workout_day_controller.dart';
import 'package:soccer_sys/modules/workouts/controllers/workout_weekly_controller.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/modules/workouts/repositories/workout_repository.dart';
import 'package:soccer_sys/modules/workouts/services/workout_service.dart';
import 'package:soccer_sys/modules/workouts/services/workout_storage_service.dart';

class WorkoutBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    Get.lazyPut<WorkoutService>(
      () => WorkoutService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<WorkoutStorageService>(
      () => WorkoutStorageService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<WorkoutRepository>(
      () => WorkoutRepository(
        Get.find<WorkoutService>(),
        Get.find<WorkoutStorageService>(),
      ),
      fenix: true,
    );
  }
}

class TraineeWorkoutBinding extends Bindings {
  @override
  void dependencies() {
    WorkoutBinding().dependencies();
    final auth = Get.find<AuthController>();
    final traineeId = auth.currentUser.value?.id;
    if (traineeId == null) return;

    _registerWeeklyController(traineeId, canManage: false);
  }
}

class TrainerTraineeWorkoutBinding extends Bindings {
  TrainerTraineeWorkoutBinding(this.traineeId);

  final String traineeId;

  @override
  void dependencies() {
    ensureWorkoutWeeklyController(
      traineeId: traineeId,
      canManage: true,
    );
  }
}

/// Registers [WorkoutWeeklyController] for the logged-in trainee (home tab).
void ensureTraineeWorkoutWeeklyController() {
  final auth = Get.find<AuthController>();
  final user = auth.currentUser.value;
  if (user == null || !user.isTrainee) return;

  ensureWorkoutWeeklyController(
    traineeId: user.id,
    canManage: false,
    permanent: true,
  );
}

void ensureWorkoutWeeklyController({
  required String traineeId,
  required bool canManage,
  bool permanent = false,
}) {
  WorkoutBinding().dependencies();

  if (Get.isRegistered<WorkoutWeeklyController>()) {
    final existing = Get.find<WorkoutWeeklyController>();
    if (existing.traineeId == traineeId && existing.canManage == canManage) {
      return;
    }
    Get.delete<WorkoutWeeklyController>(force: true);
  }

  Get.put<WorkoutWeeklyController>(
    WorkoutWeeklyController(
      Get.find<WorkoutRepository>(),
      traineeId: traineeId,
      canManage: canManage,
    ),
    permanent: permanent,
  );
}

void _registerWeeklyController(String traineeId, {required bool canManage}) {
  ensureWorkoutWeeklyController(
    traineeId: traineeId,
    canManage: canManage,
  );
}

class WorkoutDayBinding extends Bindings {
  @override
  void dependencies() {
    WorkoutBinding().dependencies();
    final args = Get.arguments as WorkoutDayArgs;
    Get.lazyPut<WorkoutDayController>(
      () => WorkoutDayController(Get.find<WorkoutRepository>(), args),
    );
  }
}

class ExerciseFormBinding extends Bindings {
  @override
  void dependencies() {
    WorkoutBinding().dependencies();
    final args = Get.arguments as ExerciseFormArgs;
    Get.lazyPut<ExerciseFormController>(
      () => ExerciseFormController(Get.find<WorkoutRepository>(), args),
    );
  }
}
