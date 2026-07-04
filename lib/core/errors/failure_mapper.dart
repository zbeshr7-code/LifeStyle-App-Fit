import 'dart:io';

import 'package:soccer_sys/core/errors/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class FailureMapper {
  static Failure fromException(Object error) {
    if (error is AuthException) {
      return AuthFailure(_mapAuth(error));
    }
    if (error is PostgrestException) {
      return ServerFailure(_mapPostgrest(error));
    }
    if (error is StorageException) {
      return ServerFailure(_mapStorage(error));
    }
    if (error is SocketException) {
      return const NetworkFailure();
    }
    return const ServerFailure('server_error');
  }

  static String _mapAuth(AuthException error) {
    final code = error.code?.toLowerCase();
    if (code != null) {
      switch (code) {
        case 'invalid_credentials':
          return 'invalid_credentials';
        case 'email_not_confirmed':
          return 'email_not_confirmed';
        case 'user_already_exists':
        case 'email_exists':
          return 'email_already_registered';
        case 'weak_password':
          return 'weak_password';
        case 'over_email_send_rate_limit':
        case 'over_request_rate_limit':
          return 'rate_limit_exceeded';
        case 'validation_failed':
          return 'invalid_email';
        case 'otp_expired':
          return 'otp_expired';
        case 'invalid_otp':
          return 'invalid_otp';
        case 'over_sms_send_rate_limit':
          return 'sms_rate_limit_exceeded';
      }
    }

    if (error.statusCode == '401' &&
        error.message.toLowerCase().contains('invalid api key')) {
      return 'invalid_api_key';
    }
    if (error.statusCode == '429') {
      return 'rate_limit_exceeded';
    }

    return _mapAuthMessage(error.message);
  }

  static String _mapPostgrest(PostgrestException error) {
    if (error.code == 'PGRST116') {
      return 'profile_not_found';
    }
    if (error.code == 'PGRST205') {
      return 'schema_outdated';
    }
    if (error.code == '42P17' ||
        error.message.toLowerCase().contains('infinite recursion')) {
      return 'server_error';
    }
    if (error.code == '23514') {
      return 'workout_invalid_sets_reps';
    }
    return 'server_error';
  }

  static String _mapStorage(StorageException error) {
    final message = error.message.toLowerCase();
    if (error.statusCode == '403' ||
        message.contains('row-level security') ||
        message.contains('not authorized')) {
      return 'workout_not_authorized';
    }
    if (message.contains('mime') ||
        message.contains('content-type') ||
        message.contains('invalid')) {
      return 'workout_photo_upload_failed';
    }
    return 'workout_photo_upload_failed';
  }

  static String _mapAuthMessage(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('database error saving new user')) {
      return 'signup_database_error';
    }
    if (lower.contains('invalid login credentials')) {
      return 'invalid_credentials';
    }
    if (lower.contains('email not confirmed')) {
      return 'email_not_confirmed';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'email_already_registered';
    }
    if (lower.contains('rate limit') || lower.contains('security purposes')) {
      return 'rate_limit_exceeded';
    }
    if (lower.contains('invalid api key')) {
      return 'invalid_api_key';
    }
    if (lower.contains('token has expired') || lower.contains('otp expired')) {
      return 'otp_expired';
    }
    if (lower.contains('invalid otp') || lower.contains('invalid token')) {
      return 'invalid_otp';
    }
    if (lower.contains('weak') && lower.contains('password')) {
      return 'weak_password';
    }
    if (lower.contains('invalid email')) {
      return 'invalid_email';
    }

    return 'auth_error';
  }
}
