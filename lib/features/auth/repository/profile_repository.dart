import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/core/services/logger_service.dart';

class ProfileRepository {
  final SupabaseClient _supabase;
  final _logger = LoggerService();

  ProfileRepository(this._supabase);

  Future<Option<UserModel>> getUserProfile(String userId) async {
  try {
    final userData = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (userData == null) return Option<UserModel>.none();
    
    return Option.of(UserModel.fromJson(userData as Map<String, dynamic>));
  } catch (e) {
    return Option<UserModel>.none();
  }
}

  Future<Either<AuthFailure, UserModel>> getOrCreateProfile({
    required String userId,
    required String email,
    required String? token,
  }) async {
    try {
      final userData = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) {
        final defaultProfile = _createDefaultProfileData(
          userId: userId,
          email: email,
          token: token,
        );

        await _supabase.from('profiles').insert(defaultProfile);
        return right(UserModel(
          id: userId,
          username: email.split('@')[0],
          email: email,
          createdAt: DateTime.now(),
          role: UserRole.user,
        ));
      }

      await _updateFcmToken(userId, token);
      return right(UserModel.fromJson(userData as Map<String, dynamic>));
    } catch (e) {
      return left(const AuthFailure.serverError());
    }
  }

  Future<Either<AuthFailure, UserModel>> createProfile({
    required String userId,
    required String email,
    required String username,
    required UserRole role,
    String? token,
  }) async {
    try {
      // First check if profile exists
      final existingProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        // Profile exists, update it instead
        final response = await _supabase
            .from('profiles')
            .update({
              'username': username,
              'role': role.toString().split('.').last,
              'fcm_token': token,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId)
            .select()
            .single();
        
        return right(UserModel.fromJson(response));
      }

      // Profile doesn't exist, create new one
      final profileData = {
        'id': userId,
        'email': email,
        'username': username,
        'role': role.toString().split('.').last,
        'fcm_token': token,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('profiles')
          .insert(profileData)
          .select()
          .single();

      return right(UserModel.fromJson(response));
    } catch (e, stackTrace) {
      _logger.error('Profile creation error', e, stackTrace);
      return left(const AuthFailure.serverError());
    }
  }

  Map<String, dynamic> _createDefaultProfileData({
    required String userId,
    required String email,
    required String? token,
  }) {
    return {
      'id': userId,
      'username': email.split('@')[0],
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
      'role': UserRole.user.toString().split('.').last,
      'fcm_token': token,
      'platform': Platform.ios == true ? 'ios' : 'android',
    };
  }

  Map<String, dynamic> _createProfileData({
    required String userId,
    required String email,
    required String username,
    required UserRole role,
    required String? token,
  }) {
    return {
      'id': userId,
      'username': username,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
      'is_online': true,
      'last_seen': DateTime.now().toIso8601String(),
      'role': role.toString().split('.').last,
      'fcm_token': token,
      'platform': Platform.ios == true ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _updateFcmToken(String userId, String? token) async {
    await _supabase
        .from('profiles')
        .update({
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }
}