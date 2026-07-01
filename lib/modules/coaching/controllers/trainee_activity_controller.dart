import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/repositories/activity_repository.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/coaching/controllers/trainee_detail_controller.dart';

class TraineeActivityController extends GetxController {
  TraineeActivityController(this._repository, this._detailController);

  final ActivityRepository _repository;
  final TraineeDetailController _detailController;

  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final weekActivities = <DailyActivityModel>[].obs;
  final todayActivity = Rx<DailyActivityModel?>(null);

  UserModel? get trainee => _detailController.trainee.value;

  String? get traineeId => trainee?.id;

  int get stepGoal => trainee?.dailyStepGoal ?? 10000;

  int get todaySteps => todayActivity.value?.steps ?? 0;

  double get todayCalories =>
      todayActivity.value?.calories ??
      ActivityMetricsCalculator.calories(
        todaySteps,
        weightKg: trainee?.currentWeight,
      );

  double get todayDistanceKm =>
      todayActivity.value?.distanceKm ??
      ActivityMetricsCalculator.distanceKm(
        todaySteps,
        heightCm: trainee?.heightCm,
      );

  StepGoalStatus get todayStatus => ActivityMetricsCalculator.statusFor(
        steps: todaySteps,
        goal: stepGoal,
        isToday: true,
      );

  bool get goalReached => todaySteps >= stepGoal && stepGoal > 0;

  int get extraStepsBeyondGoal =>
      goalReached ? todaySteps - stepGoal : 0;

  TraineeActivityContext? get activityContext {
    final t = trainee;
    if (t == null) return null;
    return TraineeActivityContext(
      traineeId: t.id,
      stepGoal: t.dailyStepGoal,
      heightCm: t.heightCm,
      weightKg: t.currentWeight,
    );
  }

  @override
  void onInit() {
    super.onInit();
    ever(_detailController.trainee, (_) => refreshAll());
    refreshAll();
  }

  Future<void> refreshAll() async {
    final id = traineeId;
    if (id == null) return;

    status.value = RxStatus.loading();
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 6));
    final result = await _repository.fetchTraineeSummary(
      traineeId: id,
      from: from,
      to: today,
    );

    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }

    weekActivities.assignAll(result.activities);
    final todayDate = _dateOnly(today);
    final todayMatches = result.activities.where(
      (a) => _dateOnly(a.activityDate) == todayDate,
    );
    todayActivity.value =
        todayMatches.isEmpty ? null : todayMatches.first;
    status.value = RxStatus.success();
  }

  void openHistory() {
    final context = activityContext;
    if (context == null) return;
    Get.toNamed(
      AppRoutes.traineeActivityHistory,
      arguments: TraineeActivityHistoryArgs(traineeContext: context),
    );
  }

  void openDayDetail(DateTime date, {DailyActivityModel? activity}) {
    final context = activityContext;
    if (context == null) return;
    Get.toNamed(
      AppRoutes.activityDay,
      arguments: ActivityDayArgs(
        date: date,
        activity: activity,
        traineeContext: context,
      ),
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
