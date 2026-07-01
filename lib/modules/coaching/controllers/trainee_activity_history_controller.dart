import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/modules/activity/models/daily_activity_model.dart';
import 'package:soccer_sys/modules/activity/repositories/activity_repository.dart';

class TraineeActivityHistoryController extends GetxController {
  TraineeActivityHistoryController(this._repository, this.context);

  final ActivityRepository _repository;
  final TraineeActivityContext context;

  static const _pageSize = 30;

  final activities = <DailyActivityModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final hasMore = true.obs;

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

    final result = await _repository.fetchHistory(
      limit: _pageSize,
      offset: _offset,
      traineeId: context.traineeId,
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

  Map<String, List<DailyActivityModel>> get groupedByMonth {
    final map = <String, List<DailyActivityModel>>{};
    for (final activity in activities) {
      final key = DateFormat.yMMMM().format(activity.activityDate);
      map.putIfAbsent(key, () => []).add(activity);
    }
    return map;
  }
}
