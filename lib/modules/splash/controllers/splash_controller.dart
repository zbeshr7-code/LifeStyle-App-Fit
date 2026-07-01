import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/initial_route.dart';

class SplashController extends GetxController {
  static const _minDisplay = Duration(milliseconds: 2600);

  @override
  void onReady() {
    super.onReady();
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    await Future<void>.delayed(_minDisplay);
    if (isClosed) return;

    final destination = InitialRoute.resolve();
    Get.offAllNamed(destination);
  }
}
