import 'package:soccer_sys/core/config/env_config.dart';

class AppConstants {
  static const String appName = 'Lifestyle Fit';

  static String get supabaseUrl => EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;

  // Shared Preferences / Storage Keys
  static const String keyIsFirstTime = 'is_first_time';
  static const String keyUserRole = 'user_role';
}
