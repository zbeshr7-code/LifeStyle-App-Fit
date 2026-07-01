import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ensures only authenticated users can access protected routes.
class AuthRequiredMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
