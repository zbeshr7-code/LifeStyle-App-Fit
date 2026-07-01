import 'package:get/get.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/coaching/repositories/coaching_repository.dart';

class TrainerClientsController extends GetxController {
  TrainerClientsController(this._repository);

  final CoachingRepository _repository;

  final trainees = <UserModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;

  int get clientCount => trainees.length;

  @override
  void onInit() {
    super.onInit();
    loadTrainees();
  }

  Future<void> loadTrainees() async {
    status.value = RxStatus.loading();
    final result = await _repository.fetchMyTrainees();
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    trainees.assignAll(result.trainees);
    status.value = RxStatus.success();
  }
}
