import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class InitialRoute {
  static String resolve() {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null ? AppRoutes.home : AppRoutes.login;
  }
}
