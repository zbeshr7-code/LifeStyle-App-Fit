import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../../steps/controllers/steps_controller.dart';
import '../../workout/controllers/workout_controller.dart';
import '../../diet/controllers/diet_controller.dart';
import '../../progress/controllers/progress_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../profile/controllers/profile_controller.dart';

import '../../../data/services/workout_service.dart';
import '../../../data/services/diet_service.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/steps_service.dart';
import '../../../data/services/chat_service.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut<WorkoutService>(() => WorkoutService());
    Get.lazyPut<DietService>(() => DietService());
    Get.lazyPut<ProgressService>(() => ProgressService());
    Get.lazyPut<StepsService>(() => StepsService());
    Get.lazyPut<ChatService>(() => ChatService());

    // Controllers
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<StepsController>(() => StepsController());
    Get.lazyPut<WorkoutController>(() => WorkoutController());
    Get.lazyPut<DietController>(() => DietController());
    Get.lazyPut<ProgressController>(() => ProgressController());
    Get.lazyPut<ChatController>(() => ChatController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
