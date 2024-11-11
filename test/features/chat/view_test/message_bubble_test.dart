import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/widgets/message_bubble.dart';

void main() {
  Widget createTestWidget({
    required ChatMessage message,
    required bool isCurrentUser,
    required String senderName,
    String? avatarUrl,
  }) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: MessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          senderName: senderName,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  group('MessageBubble Widget Tests', () {
    testWidgets('renders current user message correctly',
        (WidgetTester tester) async {
      final message = ChatMessage(
        id: 1,
        content: 'Hello!',
        senderId: 'current-user-id',
        roomId: 'test-room',
        createdAt: DateTime(2024, 1, 1, 14, 30),
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isCurrentUser: true,
          senderName: 'Current User',
        ),
      );

      // Verify content and layout
      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('Current User'),
          findsNothing); // Current user name shouldn't be shown

      // Verify alignment
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.end);

      // Verify bubble color
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Hello!'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.blue);

      // Verify text color is white for current user
      final messageText = tester.widget<Text>(find.text('Hello!'));
      expect(messageText.style?.color, Colors.white);
    });

    testWidgets('renders other user message correctly',
        (WidgetTester tester) async {
      final message = ChatMessage(
        id: 1,
        content: 'Hi there!',
        senderId: 'other-user-id',
        roomId: 'test-room',
        createdAt: DateTime(2024, 1, 1, 14, 30),
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isCurrentUser: false,
          senderName: 'Other User',
        ),
      );

      // Verify content and layout
      expect(find.text('Hi there!'), findsOneWidget);
      expect(find.text('Other User'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);

      // Verify alignment
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.start);

      // Verify bubble color for other user
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Hi there!'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey[300]);

      // Verify text color is black for other user
      final messageText = tester.widget<Text>(find.text('Hi there!'));
      expect(messageText.style?.color, Colors.black);
    });

    testWidgets('shows default avatar icon when no URL is provided',
        (WidgetTester tester) async {
      final message = ChatMessage(
        id: 1,
        content: 'Hello!',
        senderId: 'user-id',
        roomId: 'test-room',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isCurrentUser: true,
          senderName: 'User',
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isNull);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(avatar.radius, 16);
    });

    testWidgets('formats time correctly for single digit minutes',
        (WidgetTester tester) async {
      final message = ChatMessage(
        id: 1,
        content: 'Hello!',
        senderId: 'user-id',
        roomId: 'test-room',
        createdAt: DateTime(2024, 1, 1, 9, 5), // 9:05
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isCurrentUser: true,
          senderName: 'User',
        ),
      );

      expect(find.text('9:05'), findsOneWidget);
    });

    testWidgets('applies correct text styles for other user message',
        (WidgetTester tester) async {
      final message = ChatMessage(
        id: 1,
        content: 'Hi!',
        senderId: 'other-user-id',
        roomId: 'test-room',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isCurrentUser: false,
          senderName: 'Other User',
        ),
      );

      // Verify sender name style
      final senderNameText = tester.widget<Text>(find.text('Other User'));
      expect(senderNameText.style?.fontSize, 12);
      expect(senderNameText.style?.fontWeight, FontWeight.bold);
      expect(senderNameText.style?.color, Colors.grey);

      // Verify time style
      final timeText = tester.widget<Text>(
        find.text(
            '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}'),
      );
      expect(timeText.style?.fontSize, 10);
      expect(timeText.style?.color, Colors.black54);
    });

    testWidgets('verifies bubble border radius', (WidgetTester tester) async {
      final message = ChatMessage(
        id: 1,
        content: 'Hello!',
        senderId: 'user-id',
        roomId: 'test-room',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isCurrentUser: true,
          senderName: 'User',
        ),
      );

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Hello!'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('handles long messages correctly', (WidgetTester tester) async {
      final longMessage = 'A' * 100;
      final message = ChatMessage(
        id: 1,
        content: longMessage,
        senderId: 'user-id',
        roomId: 'test-room',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isCurrentUser: true,
          senderName: 'User',
        ),
      );

      expect(find.text(longMessage), findsOneWidget);
    });

    testWidgets('verifies spacing between components',
        (WidgetTester tester) async {
      final message = ChatMessage(
        id: 1,
        content: 'Hello!',
        senderId: 'other-user-id',
        roomId: 'test-room',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          message: message,
          isCurrentUser: false,
          senderName: 'Other User',
        ),
      );

      // Outer padding
      final padding = tester.widget<Padding>(
        find.byType(Padding).first,
      );
      expect(padding.padding,
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4));

      // Verify SizedBox width between avatar and message
      expect(
          find.byWidgetPredicate(
              (widget) => widget is SizedBox && widget.width == 8),
          findsOneWidget);
    });
  });
}
