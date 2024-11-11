import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_case/features/auth/model/auth_failure.dart';
import 'package:test_case/features/auth/notifiers/auth_notifier.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/auth/view/login_view.dart';
import 'package:test_case/core/services/auth_service.dart';
import 'package:test_case/features/auth/view/register_view.dart';
import 'package:test_case/features/auth/widgets/auth_button.dart';

class MockAuthService extends Mock implements IAuthService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late MockAuthService mockAuthService;
  late AuthNotifier authNotifier;
  late NavigatorObserver mockNavigatorObserver;

  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  setUp(() {
    mockAuthService = MockAuthService();
    authNotifier = AuthNotifier(mockAuthService);
    mockNavigatorObserver = MockNavigatorObserver();

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
        home: const LoginView(),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('LoginView Widget Tests', () {
    testWidgets('shows validation errors when form is submitted empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final loginButton = find.byType(AuthButton);
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
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

    testWidgets('calls sign in when form is valid',
        (WidgetTester tester) async {
      when(() => mockAuthService.signIn(
          email: 'test@example.com',
          password: 'password123')).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      verify(() => mockAuthService.signIn(
          email: 'test@example.com', password: 'password123')).called(1);
    });

    testWidgets('shows loading indicator during login',
        (WidgetTester tester) async {
      final completer = Completer<AuthFailure?>();

      when(() => mockAuthService.signIn(
              email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidgetUnderTest());

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

    testWidgets('navigates to register view when register button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(RegisterView), findsNothing);

      await tester.tap(find.text("Don't have an account? Register"));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterView), findsOneWidget);
      expect(find.byType(LoginView), findsNothing);
    });
  });
}
