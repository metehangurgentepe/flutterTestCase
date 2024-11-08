import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_case/features/auth/providers/auth_notifier.dart';
import 'package:test_case/features/auth/providers/auth_providers.dart';
import 'package:test_case/features/auth/view/login_view.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockAuthNotifier mockAuthNotifier;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
    mockNavigatorObserver = MockNavigatorObserver();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: MaterialApp(
        home: const LoginView(),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('LoginView', () {
    testWidgets('shows validation errors when fields are empty', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'invalid-email');

      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows validation error for short password', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, '12345');

      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('navigates to RegisterView when register button is tapped', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final registerButton = find.text("Don't have an account? Register");
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      verify(() => mockNavigatorObserver.didPush(any(), any())).called(1);
    });
  });
}