import '../services/diet_service.dart';
import 'package:get/get.dart';

class DietRepository {
  final DietService _service = Get.find<DietService>();

  Future<Map<String, dynamic>?> getMealPlan(String traineeId) async {
    return await _service.getMealPlan(traineeId);
  }
}
