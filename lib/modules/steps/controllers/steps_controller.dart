import 'package:get/get.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import '../../../data/repositories/steps_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/utils/error_handler.dart';

class StepsController extends GetxController {
  final StepsRepository _repository = StepsRepository();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  final RxInt steps = 0.obs;
  final RxInt goal = 10000.obs;
  final RxString status = 'stopped'.obs;
  final RxInt streakDays = 0.obs;
  final RxInt averageSteps = 0.obs;

  double get distance => (steps.value * 0.000762);
  double get calories => (steps.value * 0.04);

  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;

  @override
  void onInit() {
    super.onInit();
    loadStats();
    initPedometer();
  }

  Future<void> loadStats() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;
      
      final stats = await _repository.getActivityStats(userId);
      streakDays.value = stats['streak_days'] ?? 0;
      averageSteps.value = stats['average_steps'] ?? 0;
    } catch (e) {
      ErrorHandler.showErrorSnackbar(e);
    }
  }

  Future<void> initPedometer() async {
    try {
      if (Platform.isAndroid) {
        if (!await Permission.activityRecognition.request().isGranted) {
          return;
        }
      }

      _stepCountStream = Pedometer.stepCountStream.listen(onStepCount, onError: onStepCountError);
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(onPedestrianStatus, onError: onPedestrianStatusError);
    } catch (e) {
      ErrorHandler.showErrorSnackbar(e);
    }
  }

  void onStepCount(StepCount event) {
    steps.value = event.steps;
    final userId = _supabaseService.currentUser?.id;
    if (userId != null) {
      _repository.syncSteps(userId, steps.value, distance, calories).catchError((e) => print(e));
    }
  }

  void onPedestrianStatus(PedestrianStatus event) => status.value = event.status;
  void onStepCountError(error) => print('Step Count Error: $error');
  void onPedestrianStatusError(error) => print('Pedestrian Status Error: $error');

  @override
  void onClose() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
    super.onClose();
  }
}
