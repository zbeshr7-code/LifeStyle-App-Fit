import 'package:get/get.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/coaching/repositories/coaching_repository.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';

class ChooseTrainerController extends GetxController {
  ChooseTrainerController(this._repository, this._authController);

  final CoachingRepository _repository;
  final AuthController _authController;

  final trainers = <ChatPeerModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final isSaving = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTrainers();
  }

  Future<void> loadTrainers() async {
    status.value = RxStatus.loading();
    final result = await _repository.listAvailableTrainers();
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    trainers.assignAll(result.trainers);
    status.value = RxStatus.success();
  }

  List<ChatPeerModel> get filteredTrainers {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return trainers;
    return trainers
        .where((t) => t.fullName.toLowerCase().contains(q))
        .toList();
  }

  void updateSearch(String value) => searchQuery.value = value;

  Future<void> selectTrainer(ChatPeerModel trainer) async {
    if (isSaving.value) return;
    isSaving.value = true;
    final result = await _repository.assignTrainer(trainer.id);
    isSaving.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    _authController.currentUser.value = result.user;
    if (Get.isRegistered<SubscriptionAccessController>()) {
      await Get.find<SubscriptionAccessController>().refresh();
    }
    Get.back();
    Get.snackbar('', 'coaching_trainer_assigned'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }
}
