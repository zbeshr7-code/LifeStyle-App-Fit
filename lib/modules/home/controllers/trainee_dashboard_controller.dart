import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/utils/workout_calendar.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/nutrition/bindings/nutrition_binding.dart';
import 'package:soccer_sys/modules/nutrition/models/nutrition_meal_model.dart';
import 'package:soccer_sys/modules/nutrition/repositories/nutrition_repository.dart';
import 'package:soccer_sys/modules/workouts/bindings/workout_binding.dart';
import 'package:soccer_sys/modules/workouts/controllers/workout_weekly_controller.dart';
import 'package:soccer_sys/modules/workouts/models/workout_program_model.dart';
import 'package:soccer_sys/modules/workouts/repositories/workout_repository.dart';

class TraineeDashboardController extends GetxController {
  TraineeDashboardController(
    this._workoutRepository,
    this._nutritionRepository,
    this._authController,
  );

  final WorkoutRepository _workoutRepository;
  final NutritionRepository _nutritionRepository;
  final AuthController _authController;

  final status = Rx<RxStatus>(RxStatus.empty());
  final todayScheduleDay = Rxn<WorkoutScheduleDayModel>();
  final todayExercises = <WorkoutExerciseModel>[].obs;
  final todayMeals = <NutritionMealModel>[].obs;
  final programName = ''.obs;
  final todayWeightTrial = Rxn<WorkoutWeightTrialModel>();

  int get totalMealCalories =>
      todayMeals.fold(0, (sum, meal) => sum + meal.calories);

  NutritionDayType get todayNutritionDayType {
    final dayType = todayScheduleDay.value?.dayType;
    if (dayType == null || dayType == WorkoutDayType.rest) {
      return NutritionDayType.rest;
    }
    return NutritionDayType.workout;
  }

  String get todayNutritionDayLabel => todayNutritionDayType == NutritionDayType.rest
      ? 'nutrition_day_rest'.tr
      : 'nutrition_day_workout'.tr;

  @override
  void onInit() {
    super.onInit();
    refreshTodayPlan();

    if (Get.isRegistered<WorkoutWeeklyController>()) {
      ever(
        Get.find<WorkoutWeeklyController>().program,
        (_) => _syncWorkoutFromWeekly(),
      );
    }
  }

  Future<void> refreshTodayPlan() async {
    status.value = RxStatus.loading();

    final traineeId = _authController.currentUser.value?.id;
    if (traineeId == null) {
      status.value = RxStatus.empty();
      return;
    }

    await _loadWorkout(traineeId);
    await _loadMeals(traineeId);

    status.value = RxStatus.success();
  }

  Future<void> _loadWorkout(String traineeId) async {
    final trialResult = await _workoutRepository.fetchWeightTrialForDate(
      traineeId: traineeId,
      date: DateTime.now(),
    );
    todayWeightTrial.value = trialResult.trial;

    if (Get.isRegistered<WorkoutWeeklyController>()) {
      final weekly = Get.find<WorkoutWeeklyController>();
      if (weekly.program.value == null && !weekly.status.value.isLoading) {
        await weekly.loadProgram();
      }
      await _syncWorkoutFromWeekly();
      return;
    }

    final result = await _workoutRepository.fetchProgram(traineeId: traineeId);
    programName.value = result.program?.name ?? '';

    final trial = todayWeightTrial.value;
    if (trial != null) {
      todayScheduleDay.value = trial.scheduleDay ??
          _findScheduleDay(result.program, trial.scheduleDayId);
    } else {
      todayScheduleDay.value =
          WorkoutCalendar.scheduleDayForToday(result.program);
    }
    await _loadExercisesForToday();
  }

  WorkoutScheduleDayModel? _findScheduleDay(
    WorkoutProgramModel? program,
    String scheduleDayId,
  ) {
    if (program == null) return null;
    for (final day in program.scheduleDays) {
      if (day.id == scheduleDayId) return day;
    }
    return null;
  }

  Future<void> _syncWorkoutFromWeekly() async {
    if (!Get.isRegistered<WorkoutWeeklyController>()) return;

    final program = Get.find<WorkoutWeeklyController>().program.value;
    programName.value = program?.name ?? '';

    final trial = todayWeightTrial.value;
    if (trial != null) {
      todayScheduleDay.value = trial.scheduleDay ??
          _findScheduleDay(program, trial.scheduleDayId);
    } else {
      todayScheduleDay.value = WorkoutCalendar.scheduleDayForToday(program);
    }
    await _loadExercisesForToday();
  }

  Future<void> _loadExercisesForToday() async {
    final day = todayScheduleDay.value;
    if (day == null || !day.dayType.hasExercises) {
      todayExercises.clear();
      return;
    }

    final result = await _workoutRepository.fetchExercises(day.id);
    todayExercises.assignAll(result.exercises);
  }

  Future<void> _loadMeals(String traineeId) async {
    final result = await _nutritionRepository.fetchMeals(
      traineeId: traineeId,
      dayType: todayNutritionDayType,
    );
    todayMeals.assignAll(result.meals);
  }

  void openTodayWorkout() {
    final day = todayScheduleDay.value;
    if (day == null) return;

    if (!day.dayType.hasExercises) {
      Get.snackbar('', 'workout_rest_day_message'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.toNamed(
      AppRoutes.workoutDay,
      arguments: WorkoutDayArgs(
        scheduleDay: day,
        traineeId: _authController.currentUser.value!.id,
      ),
    );
  }

  void openNutrition() {
    Get.toNamed(AppRoutes.nutritionMeals);
  }
}

void ensureTraineeDashboardController() {
  final auth = Get.find<AuthController>();
  final user = auth.currentUser.value;
  if (user == null || !user.isTrainee) return;

  WorkoutBinding().dependencies();
  NutritionBinding().dependencies();

  if (Get.isRegistered<TraineeDashboardController>()) return;

  Get.put<TraineeDashboardController>(
    TraineeDashboardController(
      Get.find<WorkoutRepository>(),
      Get.find<NutritionRepository>(),
      auth,
    ),
    permanent: true,
  );
}
