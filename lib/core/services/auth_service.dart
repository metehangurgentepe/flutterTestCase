import 'package:test_case/features/auth/repository/auth_repository.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';
import 'package:test_case/core/notifications/service/notification_service.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';

abstract class IAuthService {
  Future<AuthFailure?> signIn({
    required String email,
    required String password,
  });

  Future<AuthFailure?> signUp({
    required String email,
    required String password,
    required String username,
    required UserRole role,
  });

  Future<AuthFailure?> signOut();
  
  UserModel? get currentUser;
  
  Stream<UserModel?> authStateChanges();
}

class AuthService implements IAuthService {
  final IAuthRepository _repository;
  final PresenceService _presenceService;
  final NotificationService _notificationService;
  UserModel? _currentUser;

  AuthService(this._repository, this._presenceService, this._notificationService);

  @override
  UserModel? get currentUser {
    if (_currentUser == null) {
      _repository.getCurrentUser().then((userOption) {
        userOption.fold(
          () => null,
          (user) {
            _currentUser = user;
            _initializeServices();
          },
        );
      });
    }
    return _currentUser;
  }

  @override
  Future<AuthFailure?> signIn({required String email, required String password}) async {
    try {
      await _presenceService.cleanupOldPresence();
      
      final result = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return result.fold(
        (failure) => failure,
        (user) async {
          _currentUser = user;
          await _initializeServices();
          return null;
        },
      );
    } catch (e) {
      return const AuthFailure.serverError();
    }
  }

  @override
  Future<AuthFailure?> signUp({
    required String email,
    required String password,
    required String username,
    required UserRole role,
  }) async {
    try {
      await _presenceService.cleanupOldPresence();
      
      final result = await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
        role: role,
      );
      
      return result.fold(
        (failure) => failure,
        (user) async {
          _currentUser = user;
          await _initializeServices();
          return null;
        },
      );
    } catch (e) {
      return const AuthFailure.serverError();
    }
  }

  @override
  Future<AuthFailure?> signOut() async {
    try {
      await _presenceService.cleanupOldPresence();
      
      final result = await _repository.signOut();
      
      return result.fold(
        (failure) => failure,
        (_) {
          _currentUser = null;
          return null;
        },
      );
    } catch (e) {
      return const AuthFailure.serverError();
    }
  }

  Future<void> _initializeServices() async {
    try {
      if (!_presenceService.isInitialized) {
        await _presenceService.initializePresence();
      }
      
      await _notificationService.initialize();
      await _notificationService.setupToken();
      _notificationService.listenToTokenRefresh();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }
  
  @override
  Stream<UserModel?> authStateChanges() {
    return _repository.authStateChanges().map(
      (userOption) => userOption.fold(
        () => null,
        (user) {
          _currentUser = user;
          return user;
        },
      ),
    );
  }
}