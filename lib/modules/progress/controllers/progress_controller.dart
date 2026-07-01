import 'package:get/get.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/utils/error_handler.dart';

class ProgressController extends GetxController {
  final ProgressRepository _repository = ProgressRepository();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  final RxBool isLoading = false.obs;
  final RxList<dynamic> progressPhotos = <dynamic>[].obs;

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

      final data = await _repository.getProgressPhotos(userId);
      progressPhotos.assignAll(data);
    } catch (e) {
      ErrorHandler.showErrorSnackbar(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addPhoto() async {
    // Picking and uploading logic
  }
}
