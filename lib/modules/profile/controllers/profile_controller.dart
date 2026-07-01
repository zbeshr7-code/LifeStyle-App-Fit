import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/repositories/profile_repository.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/coaching/repositories/coaching_repository.dart';
import 'package:soccer_sys/modules/profile/widgets/avatar_pick_sheet.dart';
import 'package:soccer_sys/modules/subscriptions/controllers/subscription_access_controller.dart';

class ProfileController extends GetxController {
  ProfileController(
    this._authController,
    this._profileRepository,
    this._coachingRepository,
  );

  final AuthController _authController;
  final ProfileRepository _profileRepository;
  final CoachingRepository _coachingRepository;

  final isUploadingAvatar = false.obs;
  final assignedTrainer = Rxn<ChatPeerModel>();
  final isLoadingTrainer = false.obs;

  Rx<UserModel?> get user => _authController.currentUser;

  @override
  void onInit() {
    super.onInit();
    loadAssignedTrainer();
    refreshSubscription();
    ever(_authController.currentUser, (_) {
      loadAssignedTrainer();
      refreshSubscription();
    });
  }

  Future<void> refreshSubscription() async {
    if (_authController.currentUser.value?.isTrainee != true) return;
    if (!Get.isRegistered<SubscriptionAccessController>()) return;
    await Get.find<SubscriptionAccessController>().refresh();
  }

  Future<void> loadAssignedTrainer() async {
    if (_authController.currentUser.value?.isTrainee != true) return;
    isLoadingTrainer.value = true;
    final result = await _coachingRepository.fetchMyTrainer();
    isLoadingTrainer.value = false;
    if (result.failure == null) {
      assignedTrainer.value = result.trainer;
    }
  }

  Future<void> showAvatarPicker() {
    return AvatarPickSheet.show(
      onGallery: () => pickAvatar(ImageSource.gallery),
      onCamera: () => pickAvatar(ImageSource.camera),
    );
  }

  Future<void> pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    isUploadingAvatar.value = true;
    final bytes = await file.readAsBytes();
    final result = await _profileRepository.uploadAndSetAvatar(
      bytes: bytes,
      fileName: file.name,
    );
    isUploadingAvatar.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    _authController.currentUser.value = result.user;
    Get.snackbar('', 'profile_avatar_updated'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  void openEdit() {
    Get.toNamed(AppRoutes.profileEdit);
  }

  void openChooseTrainer() {
    Get.toNamed(AppRoutes.chooseTrainer)?.then((_) {
      loadAssignedTrainer();
      refreshSubscription();
    });
  }

  void openSubscriptionPlans() {
    if (_authController.currentUser.value?.hasTrainer != true) {
      openChooseTrainer();
      return;
    }
    Get.toNamed(AppRoutes.subscriptionPlans)?.then((_) => refreshSubscription());
  }
}
