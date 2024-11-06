import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/auth_failure.dart';
import '../model/user_model.dart';

abstract class IAuthRepository {
  Future<Either<AuthFailure, UserModel>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, UserModel>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  });

  Future<Either<AuthFailure, Unit>> signOut();

  Future<Either<AuthFailure, UserModel>> checkAuthStatus();

  Future<Option<UserModel>> getCurrentUser();

  Stream<Option<UserModel>> authStateChanges();
}

class AuthRepository implements IAuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

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

      try {
        final userData = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        if (userData == null) {
          final newProfile = {
            'id': response.user!.id,
            'username': email.split('@')[0],
            'email': email,
            'created_at': DateTime.now().toIso8601String(),
          };

          await _supabase.from('profiles').insert(newProfile);

          return right(UserModel(
            id: response.user!.id,
            username: email.split('@')[0],
            email: email,
            createdAt: DateTime.now(),
          ));
        }

        return right(UserModel.fromJson(userData as Map<String, dynamic>));
      } catch (e) {
        return right(UserModel(
          id: response.user!.id,
          username: email.split('@')[0],
          email: email,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        return left(const AuthFailure.invalidEmailAndPasswordCombination());
      }
      if (e.toString().contains('Database error')) {
        return left(const AuthFailure.serverError());
      }
      return left(const AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, UserModel>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email:email,
        password: password
      );

      if (response.user == null) {
        return left(const AuthFailure.serverError());
      }

      try {
        final userProfile = {
          'id': response.user!.id,
          'username': username,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
          'is_online': true,
          'last_seen': DateTime.now().toIso8601String(),
        };

        await _supabase.from('profiles').insert(userProfile);

        return right(UserModel(
          id: response.user!.id,
          username: username,
          email: email,
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        return left(const AuthFailure.serverError());
      }
    } catch (e) {
      if (e.toString().contains('User already registered')) {
        return left(const AuthFailure.emailAlreadyInUse());
      }
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

      if (user == null) return none();

      try {
        final userData = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (userData == null) {
          final newProfile = {
            'id': user.id,
            'username': user.email?.split('@')[0] ?? 'user',
            'email': user.email,
            'created_at': DateTime.now().toIso8601String(),
          };

          await _supabase.from('profiles').insert(newProfile);

          final insertedData = await _supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();

          return some(UserModel.fromJson(insertedData as Map<String, dynamic>));
        }

        return some(UserModel.fromJson(userData as Map<String, dynamic>));
      } catch (e) {
        return some(UserModel(
          id: user.id,
          username: user.email?.split('@')[0] ?? 'user',
          email: user.email ?? '',
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      return none();
    }
  }

  @override
  Stream<Option<UserModel>> authStateChanges() {
    return Stream.fromIterable([none()]).asyncMap((_) async {
      final user = _supabase.auth.currentUser;
      if (user == null) return none();

      try {
        final userData = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        return some(UserModel.fromJson(userData as Map<String, dynamic>));
      } catch (e) {
        return some(UserModel(
          id: user.id,
          username: user.email ?? '',
          createdAt: DateTime.now(),
          email: '',
        ));
      }
    });
  }
  
  @override
Future<Either<AuthFailure, UserModel>> checkAuthStatus() async {
  try {
    final user = _supabase.auth.currentUser;
    
    if (user == null) {
      return left(const AuthFailure.unauthenticated());
    }

    try {
      final userData = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
          
      return right(UserModel.fromJson(userData as Map<String, dynamic>));
    } catch (e) {
      return right(UserModel(
        id: user.id,
        username: user.email?.split('@')[0] ?? 'user',
        email: user.email ?? '',
        createdAt: DateTime.now(),
      ));
    }
  } catch (e) {
    return left(const AuthFailure.serverError());
  }
}
}
