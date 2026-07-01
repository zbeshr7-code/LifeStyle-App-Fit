import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/subscriptions/models/subscription_route_args.dart';
import 'package:soccer_sys/modules/subscriptions/models/trainee_subscription_model.dart';
import 'package:soccer_sys/modules/subscriptions/repositories/subscription_repository.dart';

class TrainerSubscribersController extends GetxController {
  TrainerSubscribersController(this._repository);

  final SubscriptionRepository _repository;

  final subscribers = <TrainerSubscriberModel>[].obs;
  final status = Rx<RxStatus>(RxStatus.loading());
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSubscribers();
  }

  Future<void> loadSubscribers() async {
    status.value = RxStatus.loading();
    errorMessage.value = '';
    final result = await _repository.trainerListSubscribers();
    if (result.failure != null) {
      errorMessage.value = result.failure!.message;
      status.value = RxStatus.error(result.failure!.message);
      return;
    }
    subscribers.assignAll(result.subscribers);
    status.value =
        subscribers.isEmpty ? RxStatus.empty() : RxStatus.success();
  }

  void openEdit(TrainerSubscriberModel subscriber) {
    Get.toNamed(
      AppRoutes.trainerSubscriptionEdit,
      arguments: TrainerSubscriptionEditArgs(subscriber: subscriber),
    )?.then((_) => loadSubscribers());
  }

  void openAssign() {
    Get.toNamed(AppRoutes.trainerAssignSubscription)
        ?.then((_) => loadSubscribers());
  }
}
