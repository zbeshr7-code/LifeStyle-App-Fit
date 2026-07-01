import 'package:get/get.dart';
import '../../../data/repositories/diet_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/utils/error_handler.dart';

class DietController extends GetxController {
  final DietRepository _repository = DietRepository();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  final RxBool isLoading = false.obs;
  final RxMap mealPlan = {}.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final data = await _repository.getMealPlan(userId);
      if (data != null) {
        mealPlan.value = data;
      }
    } catch (e) {
      ErrorHandler.showErrorSnackbar(e);
    } finally {
      isLoading.value = false;
    }
  }
}
