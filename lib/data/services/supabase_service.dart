import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

class SupabaseService extends GetxService {
  late SupabaseClient client;

  Future<SupabaseService> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    client = Supabase.instance.client;
    return this;
  }

  Session? get currentSession => client.auth.currentSession;
  User? get currentUser => client.auth.currentUser;
}
