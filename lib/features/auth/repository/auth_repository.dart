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

  Future<String?> _getFcmToken() async {
    await _notificationService.initialize();
    return FirebaseMessaging.instance.getToken();
  }

  Future<Either<AuthFailure, UserModel>> _handleAuthResponse(AuthResponse response, String email) async {
    if (response.user == null) {
      return left(const AuthFailure.serverError());
    }

    final token = await _getFcmToken();
    return _profileRepository.getOrCreateProfile(
      userId: response.user!.id,
      email: email,
      token: token,
    );
  }

  Either<AuthFailure, UserModel> _handleAuthError(dynamic error) {
    if (error.toString().contains('Invalid login credentials')) {
      return left(const AuthFailure.invalidEmailAndPasswordCombination());
    }
    return left(const AuthFailure.serverError());
  }

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
      return await _handleAuthResponse(response, email);
    } catch (e) {
      return _handleAuthError(e);
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
      try {
        final existingUserQuery = await _supabase
            .from('profiles')
            .select()
            .eq('email', email)
            .maybeSingle();

        if (existingUserQuery != null) {
          return left(const AuthFailure.emailAlreadyInUse());
        }
      } catch (e) {}

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return left(const AuthFailure.serverError());
      }

      await _notificationService.initialize();
      final token = await FirebaseMessaging.instance.getToken();

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
          _supabase.auth.signOut();
          return left(failure);
        },
        (userModel) {
          return right(userModel);
        },
      );
    } catch (e, stackTrace) {
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
      if (event.session == null) {
        return const None();
      }

      final userProfile =
          await _profileRepository.getUserProfile(event.session!.user.id);

      return userProfile;
    }).handleError((error) {
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
