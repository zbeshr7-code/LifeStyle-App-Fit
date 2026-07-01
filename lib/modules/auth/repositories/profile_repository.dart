import 'package:flutter/foundation.dart';
import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/services/avatar_storage_service.dart';
import 'package:soccer_sys/modules/auth/services/profile_service.dart';

class ProfileRepository {
  ProfileRepository(this._profileService, this._avatarStorageService);

  final ProfileService _profileService;
  final AvatarStorageService _avatarStorageService;
  Future<({Failure? failure, UserModel? user})> fetchCurrentProfile() async {
    try {
      final data = await _profileService.fetchCurrentProfile();
      if (data == null) {
        return (failure: const AuthFailure('profile_not_found'), user: null);
      }
      return (failure: null, user: UserModel.fromJson(data));
    } catch (error) {
      assert(() {
        debugPrint('ProfileRepository.fetchCurrentProfile error: $error');
        return true;
      }());
      return (failure: FailureMapper.fromException(error), user: null);
    }
  }

  Future<({Failure? failure, UserModel? user})> updateDailyStepGoal(
    int goal,
  ) async {
    return updateProfile({'daily_step_goal': goal});
  }

  Future<({Failure? failure, UserModel? user})> updateProfile(
    Map<String, dynamic> fields,
  ) async {
    try {
      final data = await _profileService.updateProfile(fields);
      return (failure: null, user: UserModel.fromJson(data));
    } catch (error) {
      return (failure: FailureMapper.fromException(error), user: null);
    }
  }

  Future<({Failure? failure, UserModel? user})> uploadAndSetAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final url = await _avatarStorageService.uploadAvatar(
        bytes: bytes,
        fileName: fileName,
      );
      return updateProfile({'avatar_url': url});
    } catch (error) {
      return (failure: FailureMapper.fromException(error), user: null);
    }
  }
}
