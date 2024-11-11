import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_case/features/chat/view/chat_view.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/repository/chat_room_repository.dart';
import 'package:test_case/features/chat/provider/chat_room_providers.dart';

class MockChatRoomRepository extends Mock implements IChatRoomRepository {}

void main() {
  late ProviderContainer container;
  late MockChatRoomRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRoomRepository();
    container = ProviderContainer(
      overrides: [
        chatRoomRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    when(() => mockRepository.currentUserId).thenReturn('test-user');
    when(() => mockRepository.getMessages(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockRepository.getUserProfile(any()))
        .thenAnswer((_) => Future.value({
              'displayName': 'Test User',
              'avatarUrl': null,
            }));
  });

  tearDown(() {
    container.dispose();
  });

  Widget createTestWidget() {
    return ProviderScope(
      parent: container,
      child: const MaterialApp(
        home: ChatRoomView(
          roomId: 'test-room',
          roomName: 'Test Room',
        ),
      ),
    );
  }

  group('ChatRoomView', () {
    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows messages when loaded', (tester) async {
      final testMessage = ChatMessage(
        id: 1,
        content: 'Test message',
        senderId: 'test-user',
        roomId: 'test-room',
        createdAt: DateTime.now(),
      );

      when(() => mockRepository.getMessages(any()))
          .thenAnswer((_) => Stream.value([testMessage]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('shows empty state when no messages', (tester) async {
      when(() => mockRepository.getMessages(any()))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No messages yet'), findsOneWidget);
    });
  });
}
