import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test_case/core/services/auth_service.dart';
import 'package:test_case/features/auth/repository/auth_repository.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';
import 'package:test_case/core/notifications/service/notification_service.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

class MockPresenceService extends Mock implements PresenceService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserRole.user);
  });
  late AuthService authService;
  late MockAuthRepository mockAuthRepository;
  late MockPresenceService mockPresenceService;
  late MockNotificationService mockNotificationService;

  final testUser = UserModel(
      id: 'test-id',
      email: 'test@example.com',
      username: 'testuser',
      role: UserRole.user,
      fcmToken: 'test-token',
      createdAt: DateTime.now());

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockPresenceService = MockPresenceService();
    mockNotificationService = MockNotificationService();

    authService = AuthService(
      mockAuthRepository,
      mockPresenceService,
      mockNotificationService,
    );

    when(() => mockPresenceService.cleanupOldPresence())
        .thenAnswer((_) async => {});
    when(() => mockPresenceService.isInitialized).thenReturn(false);
    when(() => mockPresenceService.initializePresence())
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.initialize())
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.setupToken())
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.listenToTokenRefresh())
        .thenAnswer((_) => {});
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const None());
  });

  group('signIn', () {
    test('should return null on successful sign in', () async {
      when(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await authService.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isNull);
      expect(authService.currentUser, equals(testUser));

      verify(() => mockPresenceService.cleanupOldPresence()).called(1);
      verify(() => mockPresenceService.initializePresence()).called(1);
      verify(() => mockNotificationService.initialize()).called(1);
      verify(() => mockNotificationService.setupToken()).called(1);
    });

    test('should return AuthFailure on failed sign in', () async {
      when(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async =>
          const Left(AuthFailure.invalidEmailAndPasswordCombination()));

      final result = await authService.signIn(
        email: 'test@example.com',
        password: 'wrong-password',
      );

      expect(result, isA<AuthFailure>());
      expect(authService.currentUser, isNull);
    });
  });

  group('signUp', () {
    test('should return null on successful sign up', () async {
      when(
        () => mockAuthRepository.signUpWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
          username: any(named: 'username'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await authService.signUp(
        email: 'test@example.com',
        password: 'password123',
        username: 'testuser',
        role: UserRole.user,
      );

      expect(result, isNull);
      expect(authService.currentUser, equals(testUser));

      verify(() => mockPresenceService.cleanupOldPresence()).called(1);
      verify(() => mockPresenceService.initializePresence()).called(1);
      verify(() => mockNotificationService.initialize()).called(1);
      verify(() => mockNotificationService.setupToken()).called(1);
    });

    test('should return AuthFailure on failed sign up', () async {
      when(
        () => mockAuthRepository.signUpWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
          username: any(named: 'username'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async => const Left(AuthFailure.emailAlreadyInUse()));

      final result = await authService.signUp(
        email: 'existing@example.com',
        password: 'password123',
        username: 'testuser',
        role: UserRole.user,
      );

      expect(result, isA<AuthFailure>());
      expect(authService.currentUser, isNull);
    });
  });

  group('signOut', () {
    test('should return null on successful sign in', () async {
      when(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await authService.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isNull);
      expect(authService.currentUser, equals(testUser));

      verify(() => mockPresenceService.cleanupOldPresence()).called(1);
      verify(() => mockPresenceService.initializePresence()).called(1);
      verify(() => mockNotificationService.initialize()).called(1);
      verify(() => mockNotificationService.setupToken()).called(1);
    });

    test('should return AuthFailure on failed sign out', () async {
      when(() => mockAuthRepository.signOut())
          .thenAnswer((_) async => const Left(AuthFailure.serverError()));

      final result = await authService.signOut();

      expect(result, isA<AuthFailure>());
    });
  });

  group('currentUser', () {
    test('should fetch current user from repository when null', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Some(testUser));

      final currentUser = authService.currentUser;
      await Future.delayed(const Duration(milliseconds: 100));

      expect(currentUser, isNull);
      expect(authService.currentUser, equals(testUser));
    });

    test('should return null when no current user exists', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => const None());

      final currentUser = authService.currentUser;
      await Future.delayed(const Duration(milliseconds: 100));

      expect(currentUser, isNull);
      expect(authService.currentUser, isNull);
    });
  });

  group('authStateChanges', () {
    test('should emit user model on auth state change', () async {
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(Some(testUser)));

      expect(
        authService.authStateChanges(),
        emits(testUser),
      );
    });

    test('should emit null on auth state change with no user', () async {
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(const None()));

      expect(
        authService.authStateChanges(),
        emits(null),
      );
    });
  });
}
