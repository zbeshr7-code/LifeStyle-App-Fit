import '../services/workout_service.dart';
import 'package:get/get.dart';

class WorkoutRepository {
  final WorkoutService _service = Get.find<WorkoutService>();

  Future<List<Map<String, dynamic>>> getWorkoutPlans(String traineeId) async {
    return await _service.getWorkoutPlans(traineeId);
  }

  Future<bool> hasAccess(String userId) async {
    return await _service.checkUserAccess(userId);
  }
}
