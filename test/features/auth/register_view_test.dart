import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_case/features/auth/providers/auth_notifier.dart';
import 'package:test_case/features/auth/providers/auth_providers.dart';
import 'package:test_case/features/auth/view/register_view.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockAuthNotifier mockAuthNotifier;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
    mockNavigatorObserver = MockNavigatorObserver();
    
    // when(() => mockAuthNotifier.isLoading).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: MaterialApp(
        home: const RegisterView(),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('RegisterView', () {
    testWidgets('shows validation errors when fields are empty', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final registerButton = find.text('Register');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Please enter a username'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('shows validation error for short username', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final usernameField = find.widgetWithText(TextFormField, 'Username');
      await tester.enterText(usernameField, 'ab');

      final registerButton = find.text('Register');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'invalid-email');

      final registerButton = find.text('Register');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows validation error for short password', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, '12345');

      final registerButton = find.text('Register');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('navigates back to login when login button is tapped', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final loginButton = find.text('Already have an account? Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      verify(() => mockNavigatorObserver.didPop(any(), any())).called(1);
    });

    // testWidgets('shows loading indicator when registration is in progress', 
    // (WidgetTester tester) async {
    //   final asyncLoading = AsyncLoading<UserModel?>();
      
    //   await tester.pumpWidget(
    //     ProviderScope(
    //       overrides: [
    //         authStateProvider.overrideWith((ref) => mockAuthNotifier),
    //       ],
    //       child: MaterialApp(
    //         home: const RegisterView(),
    //         navigatorObservers: [mockNavigatorObserver],
    //       ),
    //     ),
    //   );

    //   expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // });

    testWidgets('submits form with valid data', 
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 
        'testuser'
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 
        'test@example.com'
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 
        'password123'
      );

      final registerButton = find.text('Register');
      await tester.tap(registerButton);
      await tester.pump();

      // Form should be valid - no validation error messages
      expect(find.text('Please enter a username'), findsNothing);
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a password'), findsNothing);
    });
  });
}