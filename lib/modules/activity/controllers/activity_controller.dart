import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/repositories/activity_repository.dart';
import 'package:soccer_sys/modules/activity/services/pedometer_service.dart';
import 'package:soccer_sys/modules/activity/utils/activity_streak_calculator.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/repositories/profile_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ActivityController extends GetxController with WidgetsBindingObserver {
  ActivityController(
    this._activityRepository,
    this._pedometerService,
    this._authController,
    this._profileRepository,
  );

  final ActivityRepository _activityRepository;
  final PedometerService _pedometerService;
  final AuthController _authController;
  final ProfileRepository _profileRepository;

  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final todaySteps = 0.obs;
  final weekActivities = <DailyActivityModel>[].obs;
  final todayActivity = Rx<DailyActivityModel?>(null);
  final streakStats = ActivityStreakStats.empty.obs;

  StreamSubscription<int>? _stepsSub;
  Timer? _syncTimer;
  Timer? _debouncedSyncTimer;
  bool _trackingStarted = false;
  bool _wasBelowGoal = true;

  static const _goalCelebratedDateKey = 'activity_goal_celebrated_date';
  static const _streakMilestoneKey = 'activity_streak_milestone_celebrated';

  int get stepGoal =>
      _authController.currentUser.value?.dailyStepGoal ?? 10000;

  double get todayCalories => ActivityMetricsCalculator.calories(
        todaySteps.value,
        weightKg: _authController.currentUser.value?.currentWeight,
      );

  double get todayDistanceKm => ActivityMetricsCalculator.distanceKm(
        todaySteps.value,
        heightCm: _authController.currentUser.value?.heightCm,
      );

  StepGoalStatus get todayStatus => ActivityMetricsCalculator.statusFor(
        steps: todaySteps.value,
        goal: stepGoal,
        isToday: true,
      );

  bool get goalReached => todaySteps.value >= stepGoal && stepGoal > 0;

  int get extraStepsBeyondGoal {
    if (!goalReached) return 0;
    return todaySteps.value - stepGoal;
  }

  bool get pedometerAvailable => _pedometerService.isAvailable;

  String get pedometerErrorKey =>
      _pedometerService.errorMessage ?? 'activity_pedometer_unavailable';

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    ever(_authController.currentUser, (user) {
      if (user?.isTrainee == true && !status.value.isLoading && !status.value.isSuccess) {
        _initTracking();
      }
    });
    if (_authController.currentUser.value?.isTrainee == true) {
      _initTracking();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepsSub?.cancel();
    _syncTimer?.cancel();
    _debouncedSyncTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshAll();
    }
  }

  Future<void> _initTracking() async {
    if (_trackingStarted) return;
    if (_authController.currentUser.value?.isTrainee != true) return;
    _trackingStarted = true;

    status.value = RxStatus.loading();
    await _pedometerService.start();
    _stepsSub = _pedometerService.stepsStream.listen((steps) {
      todaySteps.value = steps;
      _recalculateStreak();
      _maybeCelebrateGoal(steps);
      _scheduleSync();
    });
    await refreshAll();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncToday(),
    );
    status.value = RxStatus.success();
  }

  Future<void> refreshAll() async {
    await _loadWeek();
    await _loadStreakHistory();
    await _reconcileToday();
    await _initGoalCelebrationState();
    _recalculateStreak();
    await _syncToday();
  }

  Future<void> _initGoalCelebrationState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _formatDate(DateTime.now());
    final celebrated = prefs.getString(_goalCelebratedDateKey) == today;
    _wasBelowGoal = !celebrated && todaySteps.value < stepGoal;
  }

  Future<void> _maybeCelebrateGoal(int steps) async {
    final goal = stepGoal;
    if (goal <= 0) return;

    if (steps < goal) {
      return;
    }

    if (!_wasBelowGoal) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _formatDate(DateTime.now());
    if (prefs.getString(_goalCelebratedDateKey) == today) {
      _wasBelowGoal = false;
      return;
    }

    _wasBelowGoal = false;
    await prefs.setString(_goalCelebratedDateKey, today);
    _recalculateStreak();
    await _maybeCelebrateStreakMilestone(prefs);
    Get.snackbar(
      '',
      'activity_goal_congrats'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary.withValues(alpha: 0.9),
      colorText: AppColors.primaryForeground,
      duration: const Duration(seconds: 4),
      icon: Icon(Icons.emoji_events, color: AppColors.primaryForeground),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadWeek() async {
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 6));
    final result = await _activityRepository.fetchSummary(from: from, to: today);
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      return;
    }
    weekActivities.assignAll(result.activities);
    final todayDate = _dateOnly(today);
    final todayMatches = result.activities.where(
      (a) => _dateOnly(a.activityDate) == todayDate,
    );
    todayActivity.value =
        todayMatches.isEmpty ? null : todayMatches.first;
  }

  List<DailyActivityModel> _streakHistory = [];

  Future<void> _loadStreakHistory() async {
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 90));
    final result = await _activityRepository.fetchSummary(from: from, to: today);
    if (result.failure != null) return;
    _streakHistory = result.activities;
  }

  void _recalculateStreak() {
    streakStats.value = ActivityStreakCalculator.calculate(
      activities: _streakHistory,
      todaySteps: todaySteps.value,
      todayGoal: stepGoal,
      today: DateTime.now(),
    );
  }

  Future<void> _maybeCelebrateStreakMilestone(SharedPreferences prefs) async {
    final streak = streakStats.value.currentStreak;
    const milestones = [3, 7, 10, 14, 30];
    int? toCelebrate;
    for (final milestone in milestones.reversed) {
      if (streak < milestone) continue;
      final key = '$_streakMilestoneKey$milestone';
      if (prefs.getBool(key) != true) {
        toCelebrate = milestone;
      }
      break;
    }
    if (toCelebrate == null) return;
    await prefs.setBool('$_streakMilestoneKey$toCelebrate', true);
    Get.snackbar(
      '',
      'activity_streak_milestone_$toCelebrate'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.local_fire_department, color: Colors.white),
    );
  }

  Future<void> _reconcileToday() async {
    final serverSteps = todayActivity.value?.steps ?? 0;
    await _pedometerService.reconcileWithServer(
      serverSteps: serverSteps,
      date: DateTime.now(),
    );
    todaySteps.value = _pedometerService.stepsToday;
  }

  void _scheduleSync() {
    _debouncedSyncTimer?.cancel();
    _debouncedSyncTimer = Timer(const Duration(seconds: 8), _syncToday);
  }

  Future<void> _syncToday() async {
    if (todaySteps.value <= 0 && todayActivity.value == null) return;

    final steps = todaySteps.value;
    final calories = ActivityMetricsCalculator.calories(
      steps,
      weightKg: _authController.currentUser.value?.currentWeight,
    );
    final distance = ActivityMetricsCalculator.distanceKm(
      steps,
      heightCm: _authController.currentUser.value?.heightCm,
    );

    final result = await _activityRepository.upsertActivity(
      date: DateTime.now(),
      steps: steps,
      calories: calories,
      distanceKm: distance,
      goalSteps: stepGoal,
    );

    if (result.failure != null) {
      debugPrint('ActivityController._syncToday error: ${result.failure!.message}');
      errorMessage.value = result.failure!.message.tr;
      return;
    }

    if (result.activity != null) {
      todayActivity.value = result.activity;
      _upsertWeekEntry(result.activity!);
      _upsertStreakEntry(result.activity!);
      _recalculateStreak();
    }
  }

  void _upsertStreakEntry(DailyActivityModel activity) {
    final date = _dateOnly(activity.activityDate);
    final index = _streakHistory.indexWhere(
      (a) => _dateOnly(a.activityDate) == date,
    );
    if (index >= 0) {
      _streakHistory[index] = activity;
    } else {
      _streakHistory.add(activity);
      _streakHistory.sort(
        (a, b) => a.activityDate.compareTo(b.activityDate),
      );
    }
  }

  void _upsertWeekEntry(DailyActivityModel activity) {
    final date = _dateOnly(activity.activityDate);
    final index = weekActivities.indexWhere(
      (a) => _dateOnly(a.activityDate) == date,
    );
    if (index >= 0) {
      weekActivities[index] = activity;
    } else {
      weekActivities.add(activity);
      weekActivities.sort(
        (a, b) => a.activityDate.compareTo(b.activityDate),
      );
    }
    weekActivities.refresh();
  }

  Future<void> updateStepGoal(int goal) async {
    if (goal <= 0) return;
    status.value = RxStatus.loading();
    final result = await _profileRepository.updateDailyStepGoal(goal);
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    _authController.currentUser.value = result.user;
    await _syncToday();
    status.value = RxStatus.success();
  }

  void openHistory() {
    Get.toNamed(AppRoutes.activityHistory);
  }

  void openDayDetail(DateTime date, {DailyActivityModel? activity}) {
    Get.toNamed(
      AppRoutes.activityDay,
      arguments: ActivityDayArgs(date: date, activity: activity),
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
