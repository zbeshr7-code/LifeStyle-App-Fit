import '../services/progress_service.dart';
import 'package:get/get.dart';

class ProgressRepository {
  final ProgressService _service = Get.find<ProgressService>();

  Future<List<Map<String, dynamic>>> getProgressPhotos(String traineeId) async {
    return await _service.getProgressPhotos(traineeId);
  }

  Future<void> addProgressPhoto(Map<String, dynamic> data) async {
    await _service.addProgressPhoto(data);
  }
}
