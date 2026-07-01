import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/failures.dart';
import 'package:logger/logger.dart';

class ErrorHandler {
  static final _logger = Logger();

  static Failure handleException(dynamic exception) {
    _logger.e('Exception caught: $exception');

    if (exception is AuthException) {
      return AuthFailure(_mapAuthErrorMessage(exception.message), statusCode: int.tryParse(exception.statusCode ?? ''));
    } else if (exception is PostgrestException) {
      return ServerFailure(exception.message, statusCode: int.tryParse(exception.code ?? ''));
    } else if (exception is SocketException) {
      return NetworkFailure();
    } else if (exception is TimeoutException) {
      return NetworkFailure('Request timeout. Please try again.');
    } else if (exception is Failure) {
      return exception;
    } else {
      return ServerFailure('An unexpected error occurred. Please try again later.');
    }
  }

  static String _mapAuthErrorMessage(String message) {
    // Map Supabase technical messages to user-friendly localizable keys or messages
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials')) return 'invalid_credentials'.tr;
    if (msg.contains('email not confirmed')) return 'email_not_confirmed'.tr;
    if (msg.contains('user already registered')) return 'user_already_exists'.tr;
    if (msg.contains('password should be at least')) return 'password_too_short'.tr;
    if (msg.contains('over_email_send_rate_limit') || 
        msg.contains('security purposes') || 
        msg.contains('email rate limit exceeded')) {
      return 'rate_limit_exceeded'.tr;
    }
    return message;
  }

  static void showErrorSnackbar(dynamic exception) {
    final failure = handleException(exception);
    Get.snackbar(
      'error'.tr,
      failure.message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.8),
      colorText: Get.theme.colorScheme.onError,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }
}
