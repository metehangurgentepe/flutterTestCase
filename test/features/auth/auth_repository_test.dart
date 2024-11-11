import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/repository/auth_repository.dart';
import 'package:test_case/features/notifications/service/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockNotificationService extends Mock implements NotificationService {}
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockSelectBuilder extends Mock implements PostgrestTransformBuilder<PostgrestList> {}
class MockMaybeSingleBuilder extends Mock 
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  @override
  Future<U> then<U>(
    FutureOr<U> Function(Map<String, dynamic>?) onValue, {
    Function? onError,
  }) =>
      Future.value(onValue(null));
}

void main() {
  late MockSupabaseClient supabaseClient;
  late MockGoTrueClient authClient;
  late MockNotificationService notificationService;
  late AuthRepository authRepository;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder queryBuilder;
  late MockFilterBuilder filterBuilder;
  late MockSelectBuilder selectBuilder;
  late MockMaybeSingleBuilder maybeSingleBuilder;

  setUp(() {
    supabaseClient = MockSupabaseClient();
    authClient = MockGoTrueClient();
    notificationService = MockNotificationService();
    mockUser = MockUser();
    queryBuilder = MockSupabaseQueryBuilder();
    filterBuilder = MockFilterBuilder();
    selectBuilder = MockSelectBuilder();
    maybeSingleBuilder = MockMaybeSingleBuilder();
    
    when(() => supabaseClient.auth).thenReturn(authClient);
    authRepository = AuthRepository(supabaseClient, notificationService);

    registerFallbackValue({});
  });

  group('signInWithEmailAndPassword', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUserId = 'test-id';
    const testFcmToken = 'test-fcm-token';

    setUp(() {
      when(() => mockUser.id).thenReturn(testUserId);
      when(() => mockUser.email).thenReturn(testEmail);
      when(() => notificationService.initialize())
          .thenAnswer((_) async => null);
    });

    test('successful login with existing profile', () async {
      // Arrange
      when(() => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(user: mockUser));

      final mockProfileData = {
        'id': testUserId,
        'email': testEmail,
        'username': 'testuser',
        'created_at': DateTime.now().toIso8601String(),
        'role': 'user',
      };

      // Setup the query builder chain
      when(() => supabaseClient.from(any())).thenReturn(queryBuilder);
      when(() => queryBuilder.upsert(any())).thenReturn(filterBuilder);
      when(() => filterBuilder.select()).thenReturn(selectBuilder);
      when(() => selectBuilder.maybeSingle()).thenReturn(maybeSingleBuilder);
      
      // Mock the Future behavior
      when(() => maybeSingleBuilder.then(any(), onError: any(named: 'onError')))
          .thenAnswer((invocation) async => mockProfileData);

      // Act
      final result = await authRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (userModel) {
          expect(userModel.id, equals(testUserId));
          expect(userModel.email, equals(testEmail));
          expect(userModel.username, equals('testuser'));
        },
      );

      verify(() => notificationService.initialize()).called(1);
      verify(() => supabaseClient.from('profiles')).called(1);
      verify(() => queryBuilder.upsert(any())).called(1);
    });

    test('successful login with new profile creation', () async {
      // Arrange
      when(() => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(user: mockUser));

      // Setup the query builder chain
      when(() => supabaseClient.from(any())).thenReturn(queryBuilder);
      when(() => queryBuilder.upsert(any())).thenReturn(filterBuilder);
      when(() => filterBuilder.select()).thenReturn(selectBuilder);
      when(() => selectBuilder.maybeSingle()).thenReturn(maybeSingleBuilder);
      
      // Mock the Future to return null
      when(() => maybeSingleBuilder.then(any(), onError: any(named: 'onError')))
          .thenAnswer((invocation) async => null);

      // For profile creation
      when(() => queryBuilder.insert(any())).thenReturn(filterBuilder);

      // Act
      final result = await authRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (userModel) {
          expect(userModel.id, equals(testUserId));
          expect(userModel.email, equals(testEmail));
          expect(userModel.username, equals(testEmail.split('@')[0]));
          expect(userModel.role, equals(UserRole.user));
        },
      );

      verify(() => supabaseClient.from('profiles')).called(1);
      verify(() => queryBuilder.upsert(any())).called(1);
    });

    test('invalid credentials', () async {
      // Arrange
      when(() => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow('Invalid login credentials');

      // Act
      final result = await authRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure,
            const AuthFailure.invalidEmailAndPasswordCombination()),
        (userModel) => fail('Should not return user model'),
      );

      verifyNever(() => notificationService.initialize());
      verifyNever(() => supabaseClient.from(any()));
    });

    test('server error', () async {
      // Arrange
      when(() => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow('Database error');

      // Act
      final result = await authRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, const AuthFailure.serverError()),
        (userModel) => fail('Should not return user model'),
      );

      verifyNever(() => notificationService.initialize());
      verifyNever(() => supabaseClient.from(any()));
    });
  });

  group('signOut', () {
    test('successful sign out', () async {
      // Arrange
      when(() => authClient.signOut()).thenAnswer((_) async => {});

      // Act
      final result = await authRepository.signOut();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (unit) => expect(unit, equals(unit)),
      );

      verify(() => authClient.signOut()).called(1);
    });

    test('sign out with error', () async {
      // Arrange
      when(() => authClient.signOut()).thenThrow('Error signing out');

      // Act
      final result = await authRepository.signOut();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, const AuthFailure.serverError()),
        (unit) => fail('Should not return unit'),
      );

      verify(() => authClient.signOut()).called(1);
    });
  });
}