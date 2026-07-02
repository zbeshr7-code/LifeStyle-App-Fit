import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  static String get supabaseUrl =>
      _read('SUPABASE_URL', fallback: DefaultRes.supabaseUrl);

  static String get supabaseAnonKey =>
      _read('SUPABASE_ANON_KEY', fallback: DefaultRes.supabaseAnonKey);

  /// Public Agora App ID (safe in client). Certificate stays on Edge Function only.
  static String get agoraAppId =>
      _read('AGORA_APP_ID', fallback: DefaultRes.agoraAppId);

  /// Moyasar publishable key (pk_test_* or pk_live_*). Secret key stays on Edge Functions.
  static String get moyasarPublishableKey =>
      _read('MOYASAR_PUBLISHABLE_KEY', fallback: DefaultRes.moyasarPublishableKey);

  static String _read(String key, {required String fallback}) {
    final value = dotenv.env[key]?.trim();
    if (value != null && value.isNotEmpty && !value.contains('your-')) {
      return value;
    }
    return fallback;
  }
}

/// Fallback values when bundled config is missing or contains placeholders.
abstract final class DefaultRes {
  static const supabaseUrl = 'https://legcosmcypmrkyzhvbwo.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlZ2Nvc21jeXBtcmt5emh2YndvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2NDkyMTUsImV4cCI6MjA5NTIyNTIxNX0.szmiJZX9MdL37_Wtq4cYBnEGfiMojWJhK75wZvoVh5U';
  static const agoraAppId = '';
  static const moyasarPublishableKey = '';
}
