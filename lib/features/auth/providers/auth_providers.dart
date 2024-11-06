import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/repository/auth_repository.dart';
import '../model/user_model.dart';
import '../model/auth_failure.dart';
import '../repository/providers.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final IAuthRepository _repository;

  AuthNotifier(this._repository) : super(AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final userOption = await _repository.getCurrentUser();
    state = AsyncValue.data(userOption.toNullable());
  }

  Future<void> getCurrentUser() async {
    state = const AsyncValue.loading();
    try {
      final userOption = await _repository.getCurrentUser();
      state = AsyncValue.data(userOption.toNullable());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<AuthFailure?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return result.fold(
        (failure) {
          print('AuthNotifier: Login failed with ${failure.toErrorMessage()}');
          state = AsyncValue.error(failure, StackTrace.current);
          return failure;
        },
        (user) {
          state = AsyncValue.data(user);
          return null;
        },
      );
    } catch (e, stackTrace) {
      print('AuthNotifier: Unexpected error $e');
      final failure = AuthFailure.serverError();
      state = AsyncValue.error(failure, stackTrace);
      return failure;
    }
  }

  void resetState() {
    state = const AsyncData(null);
  }

  Future<AuthFailure?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    
    final result = await _repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      username: username,
    );
    
    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return failure;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<AuthFailure?> signOut() async {
    state = const AsyncValue.loading();
    
    final result = await _repository.signOut();
    
    return result.fold(
      (failure) {
        state = AsyncValue.data(state.value);
        return failure;
      },
      (_) {
        state = const AsyncValue.data(null);
        return null;
      },
    );
  }

  Future<AuthFailure?> checkAuthStatus() async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _repository.checkAuthStatus();
      
      return result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
          return failure;
        },
        (user) {
          state = AsyncValue.data(user);
          return null;
        },
      );
    } catch (e, stackTrace) {
      final failure = AuthFailure.serverError();
      state = AsyncValue.error(failure, stackTrace);
      return failure;
    }
  }

  
  bool get isAuthenticated => state.value != null;

  
  UserModel? get currentUser => state.value;

  
  bool get isLoading => state.isLoading;
}