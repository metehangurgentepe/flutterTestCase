import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/repository/auth_repository.dart';
import 'package:test_case/features/chat/provider/chat_provider.dart';
import 'package:test_case/features/notifications/service/notification_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final IAuthRepository _repository;
  final T Function<T>(ProviderListenable<T>) _read;
  final NotificationService _notificationService;

  AuthNotifier(this._repository, this._read, this._notificationService) 
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final userOption = await _repository.getCurrentUser();
      state = AsyncValue.data(userOption.toNullable());
      
      if (state.value != null) {
        await _initializePresence();
        await _initializeNotifications();
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _notificationService.setupToken();
      
      _notificationService.listenToTokenRefresh();
    } catch (e) {
      print('Error initializing notifications in AuthNotifier: $e');
    }
  }

  Future<void> _initializePresence() async {
    final presenceService = _read(presenceServiceProvider);
    if (state.value != null && !presenceService.isInitialized) {
      await presenceService.initializePresence();
    }
  }

  Future<void> _cleanupPresence() async {
    final presenceService = _read(presenceServiceProvider);
    await presenceService.dispose();
    await presenceService.cleanupOldPresence();
  }

  Future<AuthFailure?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _cleanupPresence();

      final result = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
          return failure;
        },
        (user) async {
          state = AsyncValue.data(user);
          await _initializePresence();
          await _initializeNotifications();
          return null;
        },
      );
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
      await _cleanupPresence();

      final result = await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
        role: role,
      );

      return result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
          return failure;
        },
        (user) async {
          state = AsyncValue.data(user);
          await _initializePresence();
          await _initializeNotifications();
          return null;
        },
      );
    } catch (e, stackTrace) {
      final failure = AuthFailure.serverError();
      state = AsyncValue.error(failure, stackTrace);
      return failure;
    }
  }

  Future<AuthFailure?> signOut() async {
    try {
      await _cleanupPresence();
      
      final result = await _repository.signOut();
      
      return result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
          return failure;
        },
        (_) {
          state = const AsyncValue.data(null);
          return null;
        },
      );
    } catch (e, stackTrace) {
      final failure = AuthFailure.serverError();
      state = AsyncValue.error(failure, stackTrace);
      return failure;
    }
  }

  void resetState() {
    state = const AsyncValue.data(null);
  }
}