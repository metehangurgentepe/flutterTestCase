import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/repository/auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient supabaseClient;
  late MockGoTrueClient authClient;
  late AuthRepository authRepository;

  setUp(() {
    supabaseClient = MockSupabaseClient();
    authClient = MockGoTrueClient();
    when(() => supabaseClient.auth).thenReturn(authClient);
    authRepository = AuthRepository(supabaseClient);
  });

  group('signInWithEmailAndPassword', () {
    test('should return UserModel when login is successful', () async {
      // Arrange
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('test-id');
      when(() => mockUser.email).thenReturn('test@example.com');

      // Mock the authClient signIn method
      when(() => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(
            user: mockUser,
            session: null,
          ));

      when(() => supabaseClient
              .from('profiles')
              .select()
              .eq('id', 'test-id')
              .single()
              .then((data) => data as Map<String, dynamic>))
          .thenAnswer((_) async => {
                'id': 'test-id',
                'email': 'test@example.com',
                'username': 'test'
              });

      // Act
      final result = await authRepository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.email, 'test@example.com');
          expect(r.id, 'test-id');
          expect(r.username, 'test');
        },
      );
    });

    test('should return AuthFailure when credentials are invalid', () async {
      // Arrange
      when(() => authClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow('Invalid login credentials');

      // Act
      final result = await authRepository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) =>
            expect(l, const AuthFailure.invalidEmailAndPasswordCombination()),
        (r) => fail('Should not return right'),
      );
    });
  });
}
