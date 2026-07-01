import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/repositories/activity_repository.dart';

class ActivityHistoryController extends GetxController {
  ActivityHistoryController(this._activityRepository);

  final ActivityRepository _activityRepository;

  static const _pageSize = 30;

  final activities = <DailyActivityModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final hasMore = true.obs;
  final selectedMonth = Rx<DateTime?>(null);

  int _offset = 0;
  bool _loading = false;

  @override
  void onInit() {
    super.onInit();
    loadMore();
  }

  Future<void> loadMore() async {
    if (_loading || !hasMore.value) return;
    _loading = true;
    status.value = RxStatus.loading();

    final result = await _activityRepository.fetchHistory(
      limit: _pageSize,
      offset: _offset,
    );

    _loading = false;
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }

    if (result.activities.length < _pageSize) {
      hasMore.value = false;
    }
    activities.addAll(result.activities);
    _offset += result.activities.length;
    status.value = RxStatus.success();
  }

  Future<void> reloadHistory() async {
    _offset = 0;
    hasMore.value = true;
    activities.clear();
    await loadMore();
  }

  void setMonthFilter(DateTime? month) {
    selectedMonth.value = month;
  }

  List<DailyActivityModel> get filteredActivities {
    final month = selectedMonth.value;
    if (month == null) return activities;

    return activities.where((a) {
      return a.activityDate.year == month.year &&
          a.activityDate.month == month.month;
    }).toList();
  }

  Map<String, List<DailyActivityModel>> get groupedByMonth {
    final map = <String, List<DailyActivityModel>>{};
    for (final activity in filteredActivities) {
      final key = DateFormat.yMMMM().format(activity.activityDate);
      map.putIfAbsent(key, () => []).add(activity);
    }
    return map;
  }
}
