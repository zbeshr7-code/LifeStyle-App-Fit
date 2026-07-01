import 'package:get/get.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/utils/error_handler.dart';

class WorkoutController extends GetxController {
  final WorkoutRepository _repository = WorkoutRepository();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  final RxBool isLoading = false.obs;
  final RxBool hasAccess = false.obs;
  final RxList<dynamic> workoutPlans = <dynamic>[].obs;
  final RxInt selectedDayIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    selectedDayIndex.value = (DateTime.now().weekday - 1);
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final access = await _repository.hasAccess(userId);
      hasAccess.value = access;
      
      final plans = await _repository.getWorkoutPlans(userId);
      workoutPlans.assignAll(plans);
    } catch (e) {
      ErrorHandler.showErrorSnackbar(e);
    } finally {
      isLoading.value = false;
    }
  }

  void selectDay(int index) {
    selectedDayIndex.value = index;
  }
}
