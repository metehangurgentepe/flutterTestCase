import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/providers/auth_notifier.dart';
import 'package:test_case/features/auth/repository/auth_repository.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository repository;
  late AuthNotifier authNotifier;

  setUp(() {
    repository = MockAuthRepository();
    final container = ProviderContainer();
    authNotifier = AuthNotifier(repository, container.read, notificationService);
  });

  test('initial state should be loading', () {
    expect(authNotifier.state.isLoading, true);
  });

  group('signIn', () {
    final testUser = UserModel(
      id: 'test-id',
      username: 'testuser',
      email: 'test@example.com',
      createdAt: DateTime.now(), 
      role: UserRole.admin,
    );

    test('should update state to user data when login is successful', () async {
      // Arrange
      when(() => repository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => right(testUser));

      // Act
      final failure = await authNotifier.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(failure, null);
      expect(authNotifier.state.value, testUser);
    });

    test('should update state to error when login fails', () async {
      // Arrange
      const failure = AuthFailure.invalidEmailAndPasswordCombination();
      when(() => repository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => left(failure));

      // Act
      final result = await authNotifier.signIn(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      // Assert
      expect(result, failure);
      expect(authNotifier.state.hasError, true);
    });
  });

  group('AuthNotifier Tests', () {
    late MockAuthRepository mockAuthRepository;
    late AuthNotifier authNotifier;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      container = ProviderContainer();
      authNotifier = AuthNotifier(mockAuthRepository, container.read, notificationService);  // Pass container.read instead of ref
    });

    test('signOut should clear user state and set loading to false', () async {
      // Arrange
      when(() => mockAuthRepository.signOut())
          .thenAnswer((_) async => const Right(unit));

      // Act
      await authNotifier.signOut();

      // Assert
      expect(authNotifier.state.value, null);
      expect(authNotifier.state.isLoading, false);
      verify(() => mockAuthRepository.signOut()).called(1);
    });

    test('checkAuthStatus should update state with user when authenticated', () async {
      // Arrange
      final user = UserModel(id: 'test-id', email: 'test@example.com', username: 'testuser',createdAt: DateTime.now(), role: UserRole.user);
      when(() => mockAuthRepository.checkAuthStatus())
          .thenAnswer((_) async => Right(user));

      // Act
      // await authNotifier.checkAuthStatus();

      // Assert
      expect(authNotifier.state.value, user);
      expect(authNotifier.state.isLoading, false);
      verify(() => mockAuthRepository.checkAuthStatus()).called(1);
    });

    test('signUp should update state with user on success', () async {
      // Arrange
      final user = UserModel(id: 'test-id', email: 'test@example.com', username: 'testuser',createdAt: DateTime.now(), role: UserRole.user);
      when(() => mockAuthRepository.signUpWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'), 
            role: any(named: 'role'),
          )).thenAnswer((_) async => Right(user));

      // Act
      await authNotifier.signUp(
        email: 'test@example.com',
        password: 'password123',
        username: 'testuser',
        role: UserRole.user,
      );

      // Assert
      expect(authNotifier.state.value, user);
      expect(authNotifier.state.isLoading, false);
    });

    test('signIn failure should update state with error', () async {
      // Arrange
      when(() => mockAuthRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => Left(const AuthFailure.serverError()));

      // Act
      await authNotifier.signIn(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      // Assert
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.hasError, true);
      expect(
        authNotifier.state.error,
        isA<AuthFailure>().having(
          (f) => f,
          'error',
          const AuthFailure.serverError(),
        ),
      );
    });

    test('should handle network errors during auth operations', () async {
      // Arrange
      when(() => mockAuthRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => Left(const AuthFailure.networkError()));

      // Act
      await authNotifier.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.hasError, true);
      expect(
        authNotifier.state.error,
        isA<AuthFailure>().having(
          (f) => f,
          'error',
          const AuthFailure.networkError(),
        ),
      );
    });
  });
}