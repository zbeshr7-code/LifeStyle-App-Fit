import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/core/utils/name_parser.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._supabaseService);

  final SupabaseService _supabaseService;

  SupabaseClient get _client => _supabaseService.client;

  Session? get currentSession => _supabaseService.currentSession;

  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final nameParts = NameParser.split(fullName);

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': nameParts.firstName,
        'last_name': nameParts.lastName,
        'role': role.value,
      },
    );

    final identities = response.user?.identities;
    if (identities != null && identities.isEmpty) {
      throw const AuthException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      );
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPhoneOtp({
    required String phone,
    Map<String, dynamic>? metadata,
  }) {
    return _client.auth.signInWithOtp(
      phone: phone,
      data: metadata,
    );
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> resetPassword({required String email}) {
    return _client.auth.resetPasswordForEmail(email);
  }
}
