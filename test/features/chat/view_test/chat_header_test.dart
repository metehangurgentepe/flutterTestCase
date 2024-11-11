import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';
import 'package:test_case/features/chat/provider/chat_room_providers.dart';
import 'package:test_case/features/chat/provider/presence_provider.dart';
import 'package:test_case/features/chat/widgets/chat_header_view.dart';

class MockPresenceService extends Mock implements PresenceService {}

void main() {
  late ProviderContainer container;
  late MockPresenceService mockPresenceService;

  setUp(() {
    mockPresenceService = MockPresenceService();
    container = ProviderContainer(
      overrides: [
        presenceServiceProvider.overrideWithValue(mockPresenceService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Widget createTestWidget({
    required String roomName,
    required bool isGroup,
    String? avatarUrl,
    String? userId,
    bool isOnline = false,
  }) {
    return MaterialApp(
      home: ProviderScope(
        parent: container,
        child: Scaffold(
          body: ChatHeader(
            roomName: roomName,
            isGroup: isGroup,
            avatarUrl: avatarUrl,
            userId: userId,
            isOnline: isOnline,
          ),
        ),
      ),
    );
  }

  group('ChatHeader Widget Tests', () {
    testWidgets('renders basic components correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          roomName: 'Test Room',
          isGroup: false,
        ),
      );

      expect(find.text('Test Room'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('shows offline status for individual chat',
        (WidgetTester tester) async {
      when(() => mockPresenceService.getUserPresence('user-1'))
          .thenAnswer((_) => Stream.value({'status': 'offline'}));

      await tester.pumpWidget(
        createTestWidget(
          roomName: 'Test User',
          isGroup: false,
          userId: 'user-1',
          isOnline: false,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('offline'), findsOneWidget);
    });

    testWidgets('does not show status for group chats',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          roomName: 'Group Chat',
          isGroup: true,
          userId: 'user-1',
        ),
      );

      await tester.pump();

      expect(find.text('online'), findsNothing);
      expect(find.text('offline'), findsNothing);
    });

    testWidgets('shows avatar placeholder when no avatar URL',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          roomName: 'Test User',
          isGroup: false,
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows avatar container with correct dimensions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          roomName: 'Test User',
          isGroup: false,
        ),
      );

      final avatarContainer = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.constraints?.maxWidth == 40 &&
          widget.constraints?.maxHeight == 40);

      expect(avatarContainer, findsOneWidget);
    });

    testWidgets('handles long room names', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          roomName: 'Very Long Room Name That Should Be Truncated',
          isGroup: false,
        ),
      );

      final text = tester.widget<Text>(
          find.text('Very Long Room Name That Should Be Truncated'));
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('applies correct text styles', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          roomName: 'Test User',
          isGroup: false,
          userId: 'user-1',
          isOnline: true,
        ),
      );

      final nameText = tester.widget<Text>(find.text('Test User'));
      expect(nameText.style?.fontSize, 16);
      expect(nameText.style?.fontWeight, FontWeight.w600);
    });
  });
}

extension on WidgetTester {
  Future<void> dumpWidgetTree() async {
    debugDumpApp();
    await pumpAndSettle();
  }
}
