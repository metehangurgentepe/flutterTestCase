import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/services/auth_service.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/notifiers/auth_notifier.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/auth/view/register_view.dart';
import 'package:test_case/features/auth/widgets/auth_button.dart';
import 'package:test_case/features/home/view/home_view.dart';

class MockAuthService extends Mock implements IAuthService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late AuthNotifier authNotifier;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUpAll(() {
    registerFallbackValue(UserRole.user);

    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.onAuthStateChange)
        .thenAnswer((_) => Stream.value(AuthState(
              AuthChangeEvent.signedOut,
              null,
            )));

    Supabase.initialize(
      url: 'mock-url',
      anonKey: 'mock-key',
    );
  });

  setUp(() {
    mockAuthService = MockAuthService();
    authNotifier = AuthNotifier(mockAuthService);

    when(() => mockAuthService.currentUser).thenReturn(null);
    when(() => mockAuthService.authStateChanges())
        .thenAnswer((_) => Stream.value(null));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => authNotifier),
      ],
      child: MaterialApp(
        home: const RegisterView(),
      ),
    );
  }

  group('RegisterView Widget Tests', () {
    testWidgets('shows validation errors when form is submitted empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byType(AuthButton));
      await tester.pump();

      expect(find.text('Please enter a username'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('shows error for invalid username',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'ab');

      await tester.tap(find.byType(AuthButton));
      await tester.pump();

      expect(
          find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'invalid-email');

      await tester.tap(find.byType(AuthButton));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error for short password', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), '123');

      await tester.tap(find.byType(AuthButton));
      await tester.pump();

      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('calls sign up when form is valid',
        (WidgetTester tester) async {
      when(() => mockAuthService.signUp(
            email: 'test@example.com',
            password: 'password123',
            username: 'testuser',
            role: UserRole.user,
          )).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signUp(
            email: 'test@example.com',
            password: 'password123',
            username: 'testuser',
            role: UserRole.user,
          )).called(1);
    });

    testWidgets('calls sign up with admin role when admin switch is on',
        (WidgetTester tester) async {
      when(() => mockAuthService.signUp(
            email: 'admin@example.com',
            password: 'password123',
            username: 'adminuser',
            role: UserRole.admin,
          )).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'adminuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'admin@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.byType(Switch));
      await tester.pump();

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signUp(
            email: 'admin@example.com',
            password: 'password123',
            username: 'adminuser',
            role: UserRole.admin,
          )).called(1);
    });

    testWidgets('shows error message when registration fails',
        (WidgetTester tester) async {
      when(() => mockAuthService.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
            role: any(named: 'role'),
          )).thenAnswer((_) async => const AuthFailure.emailAlreadyInUse());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.byType(AuthButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
            'This email is already registered. Please try a different email.'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator during registration',
        (WidgetTester tester) async {
      final completer = Completer<AuthFailure?>();

      when(() => mockAuthService.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
            role: any(named: 'role'),
          )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.byType(AuthButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('navigates back to login when login button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Already have an account? Login'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterView), findsNothing);
    });
  });
}
