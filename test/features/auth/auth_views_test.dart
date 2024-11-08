import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/providers/auth_notifier.dart';
import 'package:test_case/features/auth/providers/auth_providers.dart';
import 'package:test_case/features/auth/view/login_view.dart';
import 'package:test_case/features/auth/view/register_view.dart';
import 'package:test_case/features/auth/view/auth_wrapper.dart';


class MockAuthNotifier extends Mock implements AuthNotifier {}


void main() {
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
    
    // Mock the state getter with when()
    when(() => mockAuthNotifier.state)
        .thenReturn(const AsyncData(null));
    
    // Mock the signIn method
    when(() => mockAuthNotifier.signIn(
      email: any(named: 'email'), 
      password: any(named: 'password')
    )).thenAnswer((_) async => null);
    
    // Mock the signUp method
    when(() => mockAuthNotifier.signUp(
      email: any(named: 'email'),
      password: any(named: 'password'),
      username: any(named: 'username'), 
      role: any(named: 'role'),
    )).thenAnswer((_) => Future.value(null));
  });

  tearDown(() {
  reset(mockAuthNotifier);
});

  group('LoginView Tests', () {
    testWidgets('shows login form with email and password fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginView(),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text("Don't have an account? Register"), findsOneWidget);
    });

    testWidgets('calls signIn method when form is submitted',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginView(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      verify(() => mockAuthNotifier.signIn(email: 'test@example.com', password: 'password123')).called(1);
    });

    testWidgets('shows error message when login fails',
        (WidgetTester tester) async {
      when(() => mockAuthNotifier.signIn(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(AuthFailure.unauthenticated());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginView(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred'), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('handles future errors gracefully', (WidgetTester tester) async {
      final completer = Completer();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return FutureBuilder(
                future: completer.future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error occurred'));
                  }
                  return Container();
                },
              );
            },
          ),
        ),
      );

      // Kontrollü bir şekilde hata fırlat
      completer.completeError('Test error');
      
      // Hata mesajının görüntülenmesini bekle
      await tester.pumpAndSettle();
      
      expect(find.text('Error occurred'), findsOneWidget);
    });
  });

  group('RegisterView Tests', () {
    testWidgets('shows register form with all fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: RegisterView(),
          ),
        ),
      );

      expect(find.text('Register'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows error when submitting empty form',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: RegisterView(),
          ),
        ),
      );

      await tester.tap(find.text('Register'));
      await tester.pump();

      expect(find.text('Please enter a username'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('calls register method when form is submitted',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: RegisterView(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password');
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      verify(() => mockAuthNotifier.signUp(email: 'test@example.com', password: 'password', username: 'testuser', role: UserRole.user)).called(1);
    });

    testWidgets('shows loading indicator when state is loading',
        (WidgetTester tester) async {
      when(() => mockAuthNotifier.state).thenReturn(const AsyncLoading());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: RegisterView(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when registration fails',
        (WidgetTester tester) async {
      when(() => mockAuthNotifier.signUp(email: any(named: 'email'), password: any(named: 'password'), username: any(named: 'username'), role: any(named: 'role')))
      .thenAnswer((_) async => const AuthFailure.unauthenticated());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: RegisterView(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password');
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Registration failed'), findsOneWidget);
    });
  });

  group('AuthWrapper Tests', () {
    testWidgets('shows LoginView when user is null',
        (WidgetTester tester) async {
      when(() => mockAuthNotifier.state)
          .thenReturn(const AsyncData(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: AuthWrapper(),
          ),
        ),
      );

      expect(find.byType(LoginView), findsOneWidget);
    });

    // testWidgets('shows HomeView when user is authenticated',
    //     (WidgetTester tester) async {
    //   final user = UserModel(
    //     id: 'test-id',
    //     email: 'test@example.com',
    //     username: 'testuser',
    //     createdAt: DateTime.now(),
    //   );

    //   when(() => mockAuthNotifier.state)
    //       .thenReturn(AsyncData(user));

    //   await tester.pumpWidget(
    //     ProviderScope(
    //       overrides: [
    //         authStateProvider.overrideWith((ref) => mockAuthNotifier),
    //       ],
    //       child: const MaterialApp(
    //         home: AuthWrapper(),
    //       ),
    //     ),
    //   );

    //   expect(find.byType(HomeView), findsOneWidget);
    // });

    testWidgets('shows loading indicator when state is loading',
        (WidgetTester tester) async {
      when(() => mockAuthNotifier.state)
          .thenReturn(const AsyncLoading());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: AuthWrapper(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('Test error handling', (WidgetTester tester) async {
    final completer = Completer();
    await tester.pumpWidget(
      MaterialApp(
        home: FutureBuilder(
          future: completer.future,
          builder: (context, snapshot) {
            return Container();
          },
        ),
      ),
    );

    completer.completeError(42);
    await tester.pumpAndSettle();
  });
}
