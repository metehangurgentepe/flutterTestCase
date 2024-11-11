import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/repository/auth_repository.dart';
import 'package:test_case/features/auth/repository/profile_repository.dart';
import 'package:test_case/core/notifications/service/notification_service.dart';
import 'package:get_it/get_it.dart';

import 'auth_repository_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SupabaseClient>(),
  MockSpec<NotificationService>(),
  MockSpec<ProfileRepository>(),
  MockSpec<GoTrueClient>(),
  MockSpec<FirebaseMessaging>(),
])
void main() {
  late AuthRepository authRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockNotificationService mockNotificationService;
  late MockProfileRepository mockProfileRepository;
  late MockGoTrueClient mockGoTrueClient;
  late MockFirebaseMessaging mockFirebaseMessaging;

  setUpAll(() {
    provideDummy<Either<AuthFailure, UserModel>>(
      Right(UserModel(
        id: 'dummy-id',
        email: 'dummy@test.com',
        username: 'dummy',
        role: UserRole.user,
        createdAt: DateTime.now(),
      )),
    );

    provideDummy<Either<AuthFailure, Unit>>(
      const Right(unit),
    );

    provideDummy<Option<UserModel>>(
      const None(),
    );

    mockFirebaseMessaging = MockFirebaseMessaging();
    GetIt.I.registerSingleton<FirebaseMessaging>(mockFirebaseMessaging);
    when(mockFirebaseMessaging.getToken())
        .thenAnswer((_) async => 'mock-fcm-token');
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockNotificationService = MockNotificationService();
    mockProfileRepository = MockProfileRepository();
    mockGoTrueClient = MockGoTrueClient();
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

    authRepository = AuthRepository(
      mockSupabaseClient,
      mockNotificationService,
      mockProfileRepository,
    );

    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('signInWithEmailAndPassword', () {
    const email = 'test@test.com';
    const password = 'password123';
    final user = User(
      id: 'testId',
      email: email,
      appMetadata: const {},
      userMetadata: const {},
      aud: '',
      createdAt: '',
    );

    test('should return UserModel when login is successful', () async {
      final authResponse = AuthResponse(
        session: Session(
          accessToken: 'token',
          refreshToken: 'refreshToken',
          user: user,
          expiresIn: 3600,
          tokenType: 'bearer',
        ),
        user: user,
      );

      when(mockGoTrueClient.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => authResponse);

      when(mockNotificationService.initialize()).thenAnswer((_) async => null);

      when(mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => 'mock-fcm-token');

      final userModel = UserModel(
        id: user.id,
        email: email,
        username: 'testUser',
        role: UserRole.user,
        createdAt: DateTime.now(),
      );

      when(mockProfileRepository.getOrCreateProfile(
        userId: user.id,
        email: email,
        token: 'mock-fcm-token',
      )).thenAnswer((_) async => Right(userModel));

      final result = await authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      verify(mockGoTrueClient.signInWithPassword(
        email: email,
        password: password,
      )).called(1);

      verify(mockNotificationService.initialize()).called(1);

      verify(mockProfileRepository.getOrCreateProfile(
        userId: user.id,
        email: email,
        token: 'mock-fcm-token',
      )).called(1);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left: $l'),
        (r) {
          expect(r.id, equals(userModel.id));
          expect(r.email, equals(userModel.email));
          expect(r.username, equals(userModel.username));
          expect(r.role, equals(userModel.role));
        },
      );
    });

    test('should return AuthFailure when login credentials are invalid',
        () async {
      when(mockGoTrueClient.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow('Invalid login credentials');

      final result = await authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      expect(result.isLeft(), true);
      result.fold(
        (l) =>
            expect(l, const AuthFailure.invalidEmailAndPasswordCombination()),
        (r) => fail('Should not return right'),
      );
    });
  });

  group('signOut', () {
    test('should return unit when signOut is successful', () async {
      when(mockGoTrueClient.signOut()).thenAnswer((_) async => null);

      final result = await authRepository.signOut();

      expect(result.isRight(), true);
      verify(mockGoTrueClient.signOut()).called(1);
    });

    test('should return AuthFailure when signOut fails', () async {
      when(mockGoTrueClient.signOut()).thenThrow(Exception('Sign out failed'));

      final result = await authRepository.signOut();

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, const AuthFailure.serverError()),
        (r) => fail('Should not return right'),
      );
    });
  });

  group('getCurrentUser', () {
    test('should return Some(UserModel) when user is authenticated', () async {
      final user = User(
        id: 'testId',
        email: 'test@test.com',
        appMetadata: const {},
        userMetadata: const {},
        aud: '',
        createdAt: '',
      );

      when(mockGoTrueClient.currentUser).thenReturn(user);

      final userModel = UserModel(
        id: 'testId',
        email: 'test@test.com',
        username: 'testUser',
        role: UserRole.user,
        createdAt: DateTime.now(),
      );

      when(mockProfileRepository.getUserProfile(user.id))
          .thenAnswer((_) async => Some(userModel));

      final result = await authRepository.getCurrentUser();

      expect(result, Some(userModel));
    });

    test('should return None when user is not authenticated', () async {
      when(mockGoTrueClient.currentUser).thenReturn(null);

      final result = await authRepository.getCurrentUser();

      expect(result, const None());
    });
  });
}
