import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/services/fcm_service.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';

import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:soccer_sys/modules/auth/repositories/auth_repository.dart';
import 'package:soccer_sys/modules/auth/repositories/profile_repository.dart';

class AuthController extends GetxController {
  AuthController(this._authRepository, this._profileRepository);

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  final status = Rx<RxStatus>(RxStatus.empty());
  final errorMessage = ''.obs;
  final currentUser = Rx<UserModel?>(null);
  final isProfileLoading = false.obs;
  final profileLoadFailed = false.obs;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final selectedRole = Rx<UserRole?>(null);
  final termsAccepted = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Clears form fields without disposing controllers (safe during navigation).
  void clearFormFields({bool keepEmail = false}) {
    fullNameController.clear();
    if (!keepEmail) {
      emailController.clear();
    }
    passwordController.clear();
    confirmPasswordController.clear();
    selectedRole.value = null;
    termsAccepted.value = false;
    clearError();
  }

  void clearError() {
    errorMessage.value = '';
    if (status.value.isError) {
      status.value = RxStatus.empty();
    }
  }

  Future<void> register() async {
    clearError();

    final validationError = _validateRegister();
    if (validationError != null) {
      _setValidationError(validationError);
      return;
    }

    status.value = RxStatus.loading();

    final failure = await _authRepository.signUp(
      email: emailController.text.trim(),
      password: passwordController.text,
      fullName: fullNameController.text.trim(),
      role: selectedRole.value!,
    );

    if (failure != null) {
      _setFailure(failure);
      return;
    }

    if (!await _completeAuthSession()) return;

    status.value = RxStatus.success();
    Get.snackbar('', 'success_register'.tr, snackPosition: SnackPosition.BOTTOM);
    clearFormFields();
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> login() async {
    clearError();

    final validationError = _validateLogin();
    if (validationError != null) {
      _setValidationError(validationError);
      return;
    }

    status.value = RxStatus.loading();

    final failure = await _authRepository.signIn(
      email: emailController.text.trim(),
      password: passwordController.text
    );

    if (failure != null) {
      _setFailure(failure);
      return;
    }

    if (!await _completeAuthSession()) return;

    status.value = RxStatus.success();
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> forgotPassword() async {
    clearError();

    final validationError = _validateForgotPassword();
    if (validationError != null) {
      _setValidationError(validationError);
      return;
    }

    status.value = RxStatus.loading();

    final failure = await _authRepository.resetPassword(
      email: emailController.text.trim(),
    );

    if (failure != null) {
      _setFailure(failure);
      return;
    }

    status.value = RxStatus.success();
    Get.snackbar('', 'success_reset'.tr, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> logout() async {
    status.value = RxStatus.loading();
    if (Get.isRegistered<FcmService>()) {
      await Get.find<FcmService>().clearToken();
    }
    final failure = await _authRepository.signOut();
    if (failure != null) {
      _setFailure(failure);
      return;
    }
    currentUser.value = null;
    clearFormFields();
    status.value = RxStatus.empty();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> loadCurrentProfile() => _loadCurrentProfile();

  Future<void> _loadCurrentProfile() async {
    isProfileLoading.value = true;
    profileLoadFailed.value = false;

    final result = await _profileRepository.fetchCurrentProfile();

    isProfileLoading.value = false;

    if (result.failure != null) {
      profileLoadFailed.value = true;
      return;
    }

    currentUser.value = result.user;
    profileLoadFailed.value = false;
    await _setupPushNotifications();
  }

  Future<bool> _completeAuthSession() async {
    await _loadCurrentProfile();
    if (currentUser.value != null && !profileLoadFailed.value) {
      return true;
    }

    _setFailure(const AuthFailure('profile_not_found'));
    return false;
  }

  Future<void> _setupPushNotifications() async {
    if (!Get.isRegistered<FcmService>()) return;
    final fcm = Get.find<FcmService>();
    await fcm.initialize();
    await fcm.handlePendingLaunchNavigation();
  }

  String? _validateRegister() {
    if (fullNameController.text.trim().isEmpty) {
      return 'validation_name_required';
    }
    if (emailController.text.trim().isEmpty) {
      return 'validation_email_required';
    }
    if (!_isValidEmail(emailController.text.trim())) {
      return 'validation_email_invalid';
    }
    if (passwordController.text.isEmpty) {
      return 'validation_password_required';
    }
    if (passwordController.text.length < 8) {
      return 'validation_password_min';
    }
    if (passwordController.text != confirmPasswordController.text) {
      return 'validation_password_mismatch';
    }
    if (selectedRole.value == null) {
      return 'validation_role_required';
    }
    if (!termsAccepted.value) {
      return 'validation_terms_required';
    }
    return null;
  }

  String? _validateLogin() {
    if (emailController.text.trim().isEmpty) {
      return 'validation_email_required';
    }
    if (!_isValidEmail(emailController.text.trim())) {
      return 'validation_email_invalid';
    }
    if (passwordController.text.isEmpty) {
      return 'validation_password_required';
    }
    return null;
  }

  String? _validateForgotPassword() {
    if (emailController.text.trim().isEmpty) {
      return 'validation_email_required';
    }
    if (!_isValidEmail(emailController.text.trim())) {
      return 'validation_email_invalid';
    }
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _setValidationError(String key) {
    errorMessage.value = key.tr;
    status.value = RxStatus.error(key.tr);
  }

  void _setFailure(Failure failure) {
    errorMessage.value = failure.message.tr;
    status.value = RxStatus.error(failure.message.tr);
  }
}
