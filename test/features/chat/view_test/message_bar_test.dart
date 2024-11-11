import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/provider/chat_room_providers.dart';
import 'package:test_case/features/chat/provider/notifiers/messages_notifier.dart';
import 'package:test_case/features/chat/widgets/message_bar.dart';

class MockMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>>
    with Mock
    implements MessagesNotifier {
  MockMessagesNotifier() : super(const AsyncValue.data([]));
}

void main() {
  late MockMessagesNotifier mockMessagesNotifier;
  late ProviderContainer container;

  setUp(() {
    mockMessagesNotifier = MockMessagesNotifier();

    container = ProviderContainer(
      overrides: [
        messagesProvider('test-room').overrideWith((_) => mockMessagesNotifier),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ProviderScope(
        parent: container,
        child: const Scaffold(
          body: MessageBar(roomId: 'test-room'),
        ),
      ),
    );
  }

  group('MessageBar Widget Tests', () {
    testWidgets('renders basic components correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Type a message'), findsOneWidget);
    });

    testWidgets('sends message on button press', (WidgetTester tester) async {
      when(() => mockMessagesNotifier.sendMessage(any()))
          .thenAnswer((_) => Future.value());

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'Hello, World!');
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      verify(() => mockMessagesNotifier.sendMessage('Hello, World!')).called(1);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('sends message on submit', (WidgetTester tester) async {
      when(() => mockMessagesNotifier.sendMessage(any()))
          .thenAnswer((_) => Future.value());

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'Hello, World!');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(() => mockMessagesNotifier.sendMessage('Hello, World!')).called(1);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('shows loading state while sending',
        (WidgetTester tester) async {
      final completer = Completer<void>();

      when(() => mockMessagesNotifier.sendMessage(any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'Hello, World!');
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfter.enabled, true);
    });

    testWidgets('shows error message on send failure',
        (WidgetTester tester) async {
      when(() => mockMessagesNotifier.sendMessage(any()))
          .thenThrow('Failed to send message');

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'Hello, World!');
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Error sending message: Failed to send message'),
        findsOneWidget,
      );
    });

    testWidgets('does not send empty message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      verifyNever(() => mockMessagesNotifier.sendMessage(any()));
    });

    testWidgets('does not send whitespace-only message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      verifyNever(() => mockMessagesNotifier.sendMessage(any()));
    });

    testWidgets('handles multiple rapid send attempts',
        (WidgetTester tester) async {
      final completer = Completer<void>();

      when(() => mockMessagesNotifier.sendMessage(any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'Hello, World!');

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      completer.complete();
      await tester.pumpAndSettle();

      verify(() => mockMessagesNotifier.sendMessage(any())).called(1);
    });

    testWidgets('maintains text during failed send',
        (WidgetTester tester) async {
      when(() => mockMessagesNotifier.sendMessage(any()))
          .thenThrow('Failed to send message');

      await tester.pumpWidget(createTestWidget());

      const testMessage = 'Hello, World!';
      await tester.enterText(find.byType(TextField), testMessage);
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(testMessage));
    });
  });
}
