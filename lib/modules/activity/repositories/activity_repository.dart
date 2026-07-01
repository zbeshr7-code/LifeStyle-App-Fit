import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/services/activity_service.dart';

class ActivityRepository {
  ActivityRepository(this._activityService);

  final ActivityService _activityService;

  Future<({Failure? failure, DailyActivityModel? activity})> upsertActivity({
    required DateTime date,
    required int steps,
    required double calories,
    required double distanceKm,
    required int goalSteps,
  }) async {
    try {
      final data = await _activityService.upsertDailyActivity(
        date: _formatDate(date),
        steps: steps,
        calories: calories,
        distanceKm: distanceKm,
        goalSteps: goalSteps,
      );
      return (
        failure: null,
        activity: DailyActivityModel.fromJson(data),
      );
    } catch (error) {
      return (failure: FailureMapper.fromException(error), activity: null);
    }
  }

  Future<({Failure? failure, List<DailyActivityModel> activities})>
      fetchSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final data = await _activityService.getActivitySummary(
        fromDate: _formatDate(from),
        toDate: _formatDate(to),
      );
      final activities =
          data.map(DailyActivityModel.fromJson).toList();
      return (failure: null, activities: activities);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        activities: <DailyActivityModel>[],
      );
    }
  }

  Future<({Failure? failure, List<DailyActivityModel> activities})>
      fetchHistory({
    required int limit,
    required int offset,
    String? traineeId,
  }) async {
    try {
      final data = traineeId == null
          ? await _activityService.getActivityHistory(
              limit: limit,
              offset: offset,
            )
          : await _activityService.getTraineeActivityHistory(
              traineeId: traineeId,
              limit: limit,
              offset: offset,
            );
      final activities =
          data.map(DailyActivityModel.fromJson).toList();
      return (failure: null, activities: activities);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        activities: <DailyActivityModel>[],
      );
    }
  }

  Future<({Failure? failure, List<DailyActivityModel> activities})>
      fetchTraineeSummary({
    required String traineeId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final data = await _activityService.getTraineeActivitySummary(
        traineeId: traineeId,
        fromDate: _formatDate(from),
        toDate: _formatDate(to),
      );
      final activities = data.map(DailyActivityModel.fromJson).toList();
      return (failure: null, activities: activities);
    } catch (error) {
      return (
        failure: FailureMapper.fromException(error),
        activities: <DailyActivityModel>[],
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
