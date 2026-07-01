import '../services/steps_service.dart';
import 'package:get/get.dart';

class StepsRepository {
  final StepsService _service = Get.find<StepsService>();

  Future<void> syncSteps(String userId, int steps, double distance, double calories) async {
    await _service.syncSteps(userId, steps, distance, calories);
  }

  Future<Map<String, dynamic>> getActivityStats(String userId) async {
    return await _service.getActivityStats(userId);
  }
}
