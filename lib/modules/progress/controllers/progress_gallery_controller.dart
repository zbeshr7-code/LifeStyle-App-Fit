import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/progress/models/progress_entry_model.dart';
import 'package:soccer_sys/modules/progress/repositories/progress_repository.dart';

class ProgressGalleryController extends GetxController {
  ProgressGalleryController(this._repository);

  final ProgressRepository _repository;

  final entries = <ProgressEntryModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;

  int get entryCount => entries.length;

  int get photoCount =>
      entries.fold(0, (sum, e) => sum + e.photos.length);

  double? get firstWeight {
    if (entries.isEmpty) return null;
    final sorted = List<ProgressEntryModel>.from(entries)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    for (final e in sorted) {
      if (e.weightKg != null) return e.weightKg;
    }
    return null;
  }

  double? get latestWeight {
    for (final e in entries) {
      if (e.weightKg != null) return e.weightKg;
    }
    return null;
  }

  List<MapEntry<String, List<ProgressGalleryPhotoItem>>> get groupedByMonth {
    final items = <ProgressGalleryPhotoItem>[];
    for (final entry in entries) {
      for (var i = 0; i < entry.photos.length; i++) {
        items.add(ProgressGalleryPhotoItem(
          entry: entry,
          photo: entry.photos[i],
          photoIndex: i,
        ));
      }
    }

    final map = <String, List<ProgressGalleryPhotoItem>>{};
    for (final item in items) {
      final key = DateFormat.yMMMM().format(item.entry.recordedAt);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map.entries.toList()
      ..sort((a, b) {
        final da = a.value.first.entry.recordedAt;
        final db = b.value.first.entry.recordedAt;
        return db.compareTo(da);
      });
  }

  @override
  void onInit() {
    super.onInit();
    loadEntries();
  }

  Future<void> loadEntries() async {
    status.value = RxStatus.loading();
    final result = await _repository.fetchEntriesWithUrls();
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    entries.assignAll(result.entries);
    status.value = RxStatus.success();
  }

  void openAddEntry() {
    Get.toNamed(AppRoutes.progressAddEntry)?.then((_) => loadEntries());
  }

  void openPhotoDetail(ProgressGalleryPhotoItem item) {
    Get.toNamed(
      AppRoutes.progressEntryDetail,
      arguments: ProgressEntryArgs(
        entry: item.entry,
        initialPhotoIndex: item.photoIndex,
      ),
    )?.then((deleted) {
      if (deleted == true) loadEntries();
    });
  }

  Future<void> deleteEntry(ProgressEntryModel entry) async {
    final failure = await _repository.deleteEntry(entry);
    if (failure != null) {
      Get.snackbar('', failure.message.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    entries.removeWhere((e) => e.id == entry.id);
    Get.back(result: true);
    Get.snackbar('', 'progress_delete_success'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }
}
