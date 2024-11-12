import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/auth/repository/profile_repository.dart';
import 'package:test_case/core/notifications/service/notification_service.dart';
import '../model/auth_failure.dart';
import '../model/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract class IAuthRepository {
  Future<Either<AuthFailure, UserModel>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, UserModel>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required UserRole role,
  });

  Future<Either<AuthFailure, Unit>> signOut();

  Future<Either<AuthFailure, UserModel>> checkAuthStatus();

  Future<Option<UserModel>> getCurrentUser();

  Stream<Option<UserModel>> authStateChanges();
}

class AuthRepository implements IAuthRepository {
  final SupabaseClient _supabase;
  final NotificationService _notificationService;
  final ProfileRepository _profileRepository;

  AuthRepository(
    this._supabase,
    this._notificationService,
    this._profileRepository,
  );

  @override
  Future<Either<AuthFailure, UserModel>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return left(const AuthFailure.invalidEmailAndPasswordCombination());
      }

      await _notificationService.initialize();
      final token = await FirebaseMessaging.instance.getToken();
      
      return await _profileRepository.getOrCreateProfile(
        userId: response.user!.id,
        email: email,
        token: token,
      );
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        return left(const AuthFailure.invalidEmailAndPasswordCombination());
      }
      return left(const AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, UserModel>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required UserRole role,
  }) async {
    try {
      print('Starting signup process for email: $email');
      
      // Check for existing user - modified to handle empty results
      try {
        final existingUserQuery = await _supabase
            .from('profiles')
            .select()
            .eq('email', email)
            .maybeSingle();
        
        if (existingUserQuery != null) {
          print('User already exists with email: $email');
          return left(const AuthFailure.emailAlreadyInUse());
        }
      } catch (e) {
        print('Error checking existing user: $e');
        // Continue with signup if no user found
      }

      // Create auth user
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('Auth signup failed: user is null');
        return left(const AuthFailure.serverError());
      }

      print('Auth signup successful. User ID: ${response.user!.id}');

      // Get FCM token
      await _notificationService.initialize();
      final token = await FirebaseMessaging.instance.getToken();
      print('Got FCM token: $token');

      // Create profile with delay to ensure auth is completed
      await Future.delayed(const Duration(milliseconds: 500));
      
      final profileResult = await _profileRepository.createProfile(
        userId: response.user!.id,
        email: email,
        username: username,
        role: role,
        token: token,
      );

      return profileResult.fold(
        (failure) {
          print('Profile creation failed: $failure');
          _supabase.auth.signOut();
          return left(failure);
        },
        (userModel) {
          print('Profile created successfully: ${userModel.email}');
          return right(userModel);
        },
      );

    } catch (e, stackTrace) {
      print('Signup error: $e');
      print('Stack trace: $stackTrace');
      return left(const AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return right(unit);
    } catch (e) {
      return left(const AuthFailure.serverError());
    }
  }

  @override
  Future<Option<UserModel>> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return Future.value(none());
      
      return await _profileRepository.getUserProfile(user.id);
    } catch (e) {
      return Future.value(none());
    }
  }

  @override
  Stream<Option<UserModel>> authStateChanges() {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      print('Auth state changed: ${event.event}');
      
      if (event.session == null) {
        print('No session found');
        return const None();
      }
      
      final userProfile = await _profileRepository.getUserProfile(event.session!.user.id);
      print('User profile fetched: ${userProfile.toString()}');
      
      return userProfile;
    }).handleError((error) {
      print('Auth state stream error: $error');
      return const None();
    });
  }

  @override
  Future<Either<AuthFailure, UserModel>> checkAuthStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return left(const AuthFailure.unauthenticated());
      }

      final profileResult = await _profileRepository.getUserProfile(user.id);
      return profileResult.match(
        () => left(const AuthFailure.serverError()),
        (profile) => right(profile),
      );
    } catch (e) {
      return left(const AuthFailure.serverError());
    }
  }
}