import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
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
}
