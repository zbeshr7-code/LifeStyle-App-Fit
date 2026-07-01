import 'package:get/get.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/activity/controllers/activity_controller.dart';
import 'package:soccer_sys/modules/activity/controllers/activity_history_controller.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/repositories/activity_repository.dart';
import 'package:soccer_sys/modules/activity/services/activity_service.dart';
import 'package:soccer_sys/modules/activity/services/pedometer_service.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/repositories/profile_repository.dart';

class ActivityBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    Get.lazyPut<ActivityService>(
      () => ActivityService(Get.find<SupabaseService>()),
      fenix: true,
    );
    Get.lazyPut<PedometerService>(
      () => PedometerService(),
      fenix: true,
    );
    Get.lazyPut<ActivityRepository>(
      () => ActivityRepository(Get.find<ActivityService>()),
      fenix: true,
    );
    if (!Get.isRegistered<ActivityController>()) {
      Get.put<ActivityController>(
        ActivityController(
          Get.find<ActivityRepository>(),
          Get.find<PedometerService>(),
          Get.find<AuthController>(),
          Get.find<ProfileRepository>(),
        ),
        permanent: true,
      );
    }
  }
}

class ActivityHistoryBinding extends Bindings {
  @override
  void dependencies() {
    ActivityBinding().dependencies();
    Get.lazyPut<ActivityHistoryController>(
      () => ActivityHistoryController(Get.find<ActivityRepository>()),
      fenix: true,
    );
  }
}

class ActivityDayBinding extends Bindings {
  @override
  void dependencies() {
    ActivityBinding().dependencies();
    final args = Get.arguments as ActivityDayArgs;
    Get.lazyPut<ActivityDayController>(
      () => ActivityDayController(
        Get.find<ActivityRepository>(),
        Get.find<ActivityController>(),
        args,
      ),
      fenix: true,
    );
  }
}

class ActivityDayController extends GetxController {
  ActivityDayController(
    this._activityRepository,
    this._activityController,
    this.args,
  );

  final ActivityRepository _activityRepository;
  final ActivityController _activityController;
  final ActivityDayArgs args;

  final activity = Rx<DailyActivityModel?>(null);
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final weekAverage = 0.obs;

  bool get isTraineeView => args.traineeContext != null;

  bool get isToday => _isSameDay(args.date, DateTime.now());

  int get liveSteps {
    if (isTraineeView) return activity.value?.steps ?? 0;
    return isToday
        ? _activityController.todaySteps.value
        : activity.value?.steps ?? 0;
  }

  int get goalSteps =>
      activity.value?.goalSteps ??
      args.traineeContext?.stepGoal ??
      _activityController.stepGoal;

  double get calories {
    if (isTraineeView) {
      return activity.value?.calories ??
          ActivityMetricsCalculator.calories(
            liveSteps,
            weightKg: args.traineeContext?.weightKg,
          );
    }
    return isToday
        ? _activityController.todayCalories
        : activity.value?.calories ?? 0;
  }

  double get distanceKm {
    if (isTraineeView) {
      return activity.value?.distanceKm ??
          ActivityMetricsCalculator.distanceKm(
            liveSteps,
            heightCm: args.traineeContext?.heightCm,
          );
    }
    return isToday
        ? _activityController.todayDistanceKm
        : activity.value?.distanceKm ?? 0;
  }

  StepGoalStatus get dayStatus => ActivityMetricsCalculator.statusFor(
        steps: liveSteps,
        goal: goalSteps,
        isToday: isToday,
      );

  @override
  void onInit() {
    super.onInit();
    if (args.activity != null) {
      activity.value = args.activity;
    }
    _load();
  }

  Future<void> _load() async {
    status.value = RxStatus.loading();
    final from = args.date.subtract(const Duration(days: 6));
    final result = args.traineeContext != null
        ? await _activityRepository.fetchTraineeSummary(
            traineeId: args.traineeContext!.traineeId,
            from: from,
            to: args.date,
          )
        : await _activityRepository.fetchSummary(
            from: from,
            to: args.date,
          );
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }

    final dayOnly = _dateOnly(args.date);
    final dayMatches = result.activities.where(
      (a) => _dateOnly(a.activityDate) == dayOnly,
    );
    activity.value =
        dayMatches.isEmpty ? args.activity : dayMatches.first;

    if (result.activities.isNotEmpty) {
      final total =
          result.activities.fold<int>(0, (sum, a) => sum + a.steps);
      weekAverage.value = (total / result.activities.length).round();
    }

    status.value = RxStatus.success();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
