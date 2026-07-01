import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/core/errors/failure.dart';
import 'package:soccer_sys/core/errors/failure_mapper.dart';
import 'package:soccer_sys/core/localization/app_translations.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/core/utils/name_parser.dart';
import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('AppTranslations includes Arabic auth strings', () {
    final translations = AppTranslations();
    expect(translations.keys['ar']!['login_title'], 'تسجيل الدخول');
    expect(translations.keys['en']!['login_title'], 'Sign In');
  });

  test('Design tokens define dark theme primary color', () {
    expect(AppColors.primary, isNotNull);
    expect(AppColors.background, isNotNull);
  });

  test('NameParser splits full name into first and last', () {
    final parts = NameParser.split('أحمد محمد');
    expect(parts.firstName, 'أحمد');
    expect(parts.lastName, 'محمد');
  });

  test('UserModel.fromJson maps Supabase profiles row', () {
    final user = UserModel.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'first_name': 'Sara',
      'last_name': 'Ali',
      'email': 'sara@example.com',
      'role': 'trainer',
      'is_active': true,
      'is_verified': false,
      'is_deleted': false,
      'created_at': '2026-06-01T00:00:00.000Z',
      'updated_at': '2026-06-01T00:00:00.000Z',
    });

    expect(user.fullName, 'Sara Ali');
    expect(user.role, UserRole.trainer);
    expect(user.isTrainer, isTrue);
  });

  test('FailureMapper maps email_not_confirmed code', () {
    const error = AuthException(
      'Email not confirmed',
      statusCode: '400',
      code: 'email_not_confirmed',
    );
    final failure = FailureMapper.fromException(error);
    expect(failure, isA<AuthFailure>());
    expect(failure.message, 'email_not_confirmed');
  });

  test('FailureMapper maps 401 to invalid_api_key', () {
    const error = AuthException(
      'Invalid API key',
      statusCode: '401',
    );
    final failure = FailureMapper.fromException(error);
    expect(failure.message, 'invalid_api_key');
  });
}
