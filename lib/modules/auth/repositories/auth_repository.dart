import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/core/utils/name_parser.dart';
import 'package:soccer_sys/modules/auth/models/phone_auth_intent.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:soccer_sys/modules/auth/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  Future<Failure?> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      if (response.session == null) {
        await _authService.signIn(email: email, password: password);
      }

      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<Failure?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signIn(email: email, password: password);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<Failure?> resetPassword({required String email}) async {
    try {
      await _authService.resetPassword(email: email);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<Failure?> signOut() async {
    try {
      await _authService.signOut();
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<Failure?> sendPhoneOtp({
    required String phone,
    required PhoneAuthIntent intent,
    String? fullName,
    UserRole? role,
  }) async {
    try {
      Map<String, dynamic>? metadata;
      if (intent == PhoneAuthIntent.register) {
        final nameParts = NameParser.split(fullName ?? '');
        metadata = {
          'first_name': nameParts.firstName,
          'last_name': nameParts.lastName,
          'role': role!.value,
        };
      }

      await _authService.sendPhoneOtp(phone: phone, metadata: metadata);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }

  Future<Failure?> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      await _authService.verifyPhoneOtp(phone: phone, token: token);
      return null;
    } catch (error) {
      return FailureMapper.fromException(error);
    }
  }
}
