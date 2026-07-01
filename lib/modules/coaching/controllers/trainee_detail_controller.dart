import 'package:get/get.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/coaching/models/trainee_detail_args.dart';
import 'package:soccer_sys/modules/coaching/repositories/coaching_repository.dart';

class TraineeDetailController extends GetxController {
  TraineeDetailController(this._repository);

  final CoachingRepository _repository;

  late final String traineeId;
  final trainee = Rxn<UserModel>();
  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as TraineeDetailArgs;
    traineeId = args.trainee.id;
    trainee.value = args.trainee;
    refreshTrainee();
  }

  Future<void> refreshTrainee() async {
    status.value = RxStatus.loading();
    final result = await _repository.fetchTraineeById(traineeId);
    if (result.failure != null) {
      errorMessage.value = result.failure!.message.tr;
      status.value = RxStatus.error(result.failure!.message.tr);
      return;
    }
    if (result.trainee != null) {
      trainee.value = result.trainee;
    }
    status.value = RxStatus.success();
  }
}
