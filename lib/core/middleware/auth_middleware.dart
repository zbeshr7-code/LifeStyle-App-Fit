import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/supabase_service.dart';
import '../../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final supabase = Get.find<SupabaseService>();
    
    if (supabase.currentSession == null) {
      return const RouteSettings(name: Routes.LOGIN);
    }
    return null;
  }
}
