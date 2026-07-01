import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'package:get/get.dart';
import '../../core/utils/error_handler.dart';

class AuthRepository {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.name,
        },
      );
      
      if (response.user != null) {
        await _createProfile(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          role: role,
        );
      }
      
      return response;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<void> _createProfile({
    required String id,
    required String email,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      await _client.from('profiles').insert({
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.name,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<UserModel?> getUserProfile(String id) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<void> updateProfile({
    required String id,
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final updates = {
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _client.from('profiles').update(updates).eq('id', id);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  Future<String> uploadAvatar(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final extension = filePath.split('.').last;
      final path = '$userId/avatar.$extension';
      
      await _client.storage.from('avatars').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
