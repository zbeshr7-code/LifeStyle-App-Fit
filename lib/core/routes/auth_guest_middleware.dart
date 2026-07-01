import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Redirects authenticated users away from guest-only routes (login, register, etc.).
class AuthGuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}
