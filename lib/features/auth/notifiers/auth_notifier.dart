import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/services/auth_service.dart';
import 'package:test_case/core/services/logger_service.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final IAuthService _authService;
  final _logger = LoggerService();
  StreamSubscription<UserModel?>? _authStateSubscription;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Initial state check
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        state = AsyncValue.data(currentUser);
      } else {
        state = const AsyncValue.data(null);
      }

      // Listen to auth state changes
      _authStateSubscription = _authService.authStateChanges().listen(
        (user) {
          state = AsyncValue.data(user);
        },
        onError: (error, stack) {
          _logger.error('Auth state error', error, stack);
          state = AsyncValue.error(error, stack);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error during auth initialization', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<AuthFailure?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final failure = await _authService.signIn(
        email: email,
        password: password,
      );

      if (failure != null) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure;
      }

      state = AsyncValue.data(_authService.currentUser);
      return null;
    } catch (e, stackTrace) {
      final failure = AuthFailure.serverError();
      state = AsyncValue.error(failure, stackTrace);
      return failure;
    }
  }

  Future<AuthFailure?> signUp({
    required String email,
    required String password,
    required String username,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final failure = await _authService.signUp(
        email: email,
        password: password,
        username: username,
        role: role,
      );

      if (failure != null) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure;
      }

      // Force state update with current user
      final currentUser = _authService.currentUser;
      _logger.info('SignUp successful for user: ${currentUser?.email}');
      state = AsyncValue.data(currentUser);
      return null;
    } catch (e, stackTrace) {
      _logger.error('SignUp error', e, stackTrace);
      final failure = AuthFailure.serverError();
      state = AsyncValue.error(failure, stackTrace);
      return failure;
    }
  }

  Future<AuthFailure?> signOut() async {
    state = const AsyncValue.loading();
    try {
      final failure = await _authService.signOut();
      
      if (failure != null) {
        state = AsyncValue.error(failure, StackTrace.current);
        return failure;
      }

      state = const AsyncValue.data(null);
      return null;
    } catch (e, stackTrace) {
      final failure = AuthFailure.serverError();
      state = AsyncValue.error(failure, stackTrace);
      return failure;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final currentUser = _authService.currentUser;
    return currentUser;
  }

  void resetState() {
    state = const AsyncValue.data(null);
  }

  Future<void> checkAuthStatus() async {
    state = const AsyncValue.loading();
    final result = await _authService.checkAuthStatus();
    state = result.fold(
      (failure) => const AsyncValue.data(null),
      (user) => AsyncValue.data(user),
    );
  }
}