import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/models/activity_level.dart';
import 'package:soccer_sys/modules/auth/models/gender.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/repositories/profile_repository.dart';

class ProfileEditController extends GetxController {
  ProfileEditController(this._authController, this._profileRepository);

  final AuthController _authController;
  final ProfileRepository _profileRepository;

  final formKey = GlobalKey<FormState>();
  final isSaving = false.obs;

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController phoneController;
  late final TextEditingController bioController;
  late final TextEditingController specializationController;
  late final TextEditingController certificationController;
  late final TextEditingController hourlyRateController;
  late final TextEditingController experienceController;
  late final TextEditingController fitnessGoalController;
  late final TextEditingController heightController;
  late final TextEditingController currentWeightController;
  late final TextEditingController targetWeightController;
  late final TextEditingController stepGoalController;

  final selectedGender = Rxn<Gender>();
  final selectedActivityLevel = Rxn<ActivityLevel>();
  final dateOfBirth = Rxn<DateTime>();

  UserModel? get user => _authController.currentUser.value;
  bool get isTrainer => user?.isTrainer ?? false;

  @override
  void onInit() {
    super.onInit();
    final u = user;
    firstNameController = TextEditingController(text: u?.firstName ?? '');
    lastNameController = TextEditingController(text: u?.lastName ?? '');
    phoneController = TextEditingController(text: u?.phoneNumber ?? '');
    bioController = TextEditingController(text: u?.bio ?? '');
    specializationController =
        TextEditingController(text: u?.specialization ?? '');
    certificationController =
        TextEditingController(text: u?.certification ?? '');
    hourlyRateController = TextEditingController(
      text: u?.hourlyRate?.toString() ?? '',
    );
    experienceController = TextEditingController(
      text: u?.yearsOfExperience?.toString() ?? '',
    );
    fitnessGoalController = TextEditingController(text: u?.fitnessGoal ?? '');
    heightController = TextEditingController(
      text: u?.heightCm?.toString() ?? '',
    );
    currentWeightController = TextEditingController(
      text: u?.currentWeight?.toString() ?? '',
    );
    targetWeightController = TextEditingController(
      text: u?.targetWeight?.toString() ?? '',
    );
    stepGoalController = TextEditingController(
      text: (u?.dailyStepGoal ?? 10000).toString(),
    );
    selectedGender.value = u?.gender;
    selectedActivityLevel.value = u?.activityLevel;
    dateOfBirth.value = u?.dateOfBirth;
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    bioController.dispose();
    specializationController.dispose();
    certificationController.dispose();
    hourlyRateController.dispose();
    experienceController.dispose();
    fitnessGoalController.dispose();
    heightController.dispose();
    currentWeightController.dispose();
    targetWeightController.dispose();
    stepGoalController.dispose();
    super.onClose();
  }

  Future<void> pickDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth.value ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      dateOfBirth.value = picked;
    }
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isSaving.value = true;
    final fields = <String, dynamic>{
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'phone_number': _nullableText(phoneController.text),
      'bio': _nullableText(bioController.text),
      'gender': selectedGender.value?.name,
      'date_of_birth': dateOfBirth.value?.toIso8601String().split('T').first,
    };

    if (isTrainer) {
      fields.addAll({
        'specialization': _nullableText(specializationController.text),
        'years_of_experience': _parseInt(experienceController.text),
        'certification': _nullableText(certificationController.text),
        'hourly_rate': _parseDouble(hourlyRateController.text),
      });
    } else {
      fields.addAll({
        'fitness_goal': _nullableText(fitnessGoalController.text),
        'height_cm': _parseDouble(heightController.text),
        'current_weight': _parseDouble(currentWeightController.text),
        'target_weight': _parseDouble(targetWeightController.text),
        'activity_level': selectedActivityLevel.value?.value,
        'daily_step_goal': _parseInt(stepGoalController.text) ?? 10000,
      });
    }

    final result = await _profileRepository.updateProfile(fields);
    isSaving.value = false;

    if (result.failure != null) {
      Get.snackbar('', result.failure!.message.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    _authController.currentUser.value = result.user;
    Get.back();
    Get.snackbar('', 'profile_save_success'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  double? _parseDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
}
