import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/provider/notifiers/chat_notifier.dart';
import 'package:test_case/features/chat/provider/notifiers/messages_notifier.dart';
import 'package:test_case/features/chat/provider/notifiers/user_profile_notifier.dart';
import 'package:test_case/features/chat/repository/chat_room_repository.dart';

import 'chat_notifier_test.mocks.dart';

@GenerateMocks([
  IChatRoomRepository,
  SupabaseClient,
  PostgrestBuilder,
  PostgrestFilterBuilder,
])
void main() {
  group('ChatNotifier Tests', () {
    late MockIChatRoomRepository mockRepository;
    late ChatNotifier notifier;

    setUp(() {
      mockRepository = MockIChatRoomRepository();
      notifier = ChatNotifier(mockRepository);
    });

    test('initial state should be AsyncData with null', () {
      expect(notifier.debugState, const AsyncValue<void>.data(null));
    });

    test('sendMessage should follow loading-success state pattern', () async {
      final message = ChatMessage(
        id: null,
        senderId: 'user1',
        content: 'Hello',
        createdAt: DateTime.now(),
        roomId: 'room1',
      );

      when(mockRepository.sendMessage(message))
          .thenAnswer((_) => Future.value());

      // Check initial state
      expect(notifier.debugState, const AsyncValue<void>.data(null));

      // Start sending message
      final future = notifier.sendMessage(message);

      // Should be in loading state
      expect(notifier.debugState, const AsyncValue<void>.loading());

      // Wait for completion
      await future;

      // Should be back to data state
      expect(notifier.debugState, const AsyncValue<void>.data(null));
      verify(mockRepository.sendMessage(message)).called(1);
    });

    test('sendMessage should handle errors', () async {
      final message = ChatMessage(
        id: null,
        senderId: 'user1',
        content: 'Hello',
        createdAt: DateTime.now(),
        roomId: 'room1',
      );

      final error = Exception('Failed to send message');
      when(mockRepository.sendMessage(message)).thenThrow(error);

      await notifier.sendMessage(message);

      expect(
        notifier.debugState,
        isA<AsyncError>().having((e) => e.error, 'error', error),
      );
    });
  });

  group('MessagesNotifier Tests', () {
    late MockIChatRoomRepository mockRepository;
    late MessagesNotifier notifier;
    const roomId = 'room1';

    setUp(() {
      mockRepository = MockIChatRoomRepository();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('should handle message stream updates', () async {
      final initialMessages = [
        ChatMessage(
          id: 1,
          senderId: 'user1',
          content: 'Hello',
          createdAt: DateTime.now(),
          roomId: roomId,
        ),
      ];

      final controller = StreamController<List<ChatMessage>>.broadcast();
      when(mockRepository.getMessages(roomId))
          .thenAnswer((_) => controller.stream);

      notifier = MessagesNotifier(mockRepository, roomId);
      await pumpEventQueue();

      controller.add(initialMessages);
      await pumpEventQueue();

      expect(
        notifier.debugState,
        isA<AsyncData<List<ChatMessage>>>()
            .having((d) => d.value, 'messages', initialMessages),
      );

      await controller.close();
    });

    test('should handle message sending with stream updates', () async {
      // Setup
      final controller = StreamController<List<ChatMessage>>.broadcast();
      final completer = Completer<void>();
      
      when(mockRepository.getMessages(roomId))
          .thenAnswer((_) => controller.stream);
      when(mockRepository.currentUserId).thenReturn('user1');
      when(mockRepository.sendMessage(any))
          .thenAnswer((_) async {
            // Simulate quick network response
            return Future.value();
          });

      // Initialize
      notifier = MessagesNotifier(mockRepository, roomId);
      await pumpEventQueue();

      // Add initial empty state
      controller.add([]);
      await pumpEventQueue();

      // Create expected message
      final expectedMessage = ChatMessage(
        id: null,
        senderId: 'user1',
        content: 'Hello',
        createdAt: DateTime.now(), 
        roomId: roomId,
      );

      // Send message
      unawaited(notifier.sendMessage('Hello'));
      await pumpEventQueue();

      // Verify message was attempted to be sent
      verify(mockRepository.sendMessage(argThat(
        isA<ChatMessage>()
            .having((m) => m.content, 'content', 'Hello')
            .having((m) => m.senderId, 'senderId', 'user1')
            .having((m) => m.roomId, 'roomId', roomId)
      ))).called(1);

      // Add response to stream
      final updatedMessages = [
        ChatMessage(
          id: 1,
          senderId: 'user1',
          content: 'Hello',
          createdAt: DateTime.now(),
          roomId: roomId,
        ),
      ];
      controller.add(updatedMessages);
      await pumpEventQueue();

      // Verify final state
      expect(
        notifier.debugState,
        isA<AsyncData<List<ChatMessage>>>()
            .having((d) => d.value, 'messages', updatedMessages),
      );

      // Cleanup
      await controller.close();
    });

    test('should handle multiple messages', () async {
      final controller = StreamController<List<ChatMessage>>.broadcast();
      when(mockRepository.getMessages(roomId))
          .thenAnswer((_) => controller.stream);
      when(mockRepository.currentUserId).thenReturn('user1');
      when(mockRepository.sendMessage(any))
          .thenAnswer((_) => Future<void>.value());

      notifier = MessagesNotifier(mockRepository, roomId);
      await pumpEventQueue();

      // Send first message
      final message1 = ChatMessage(
        id: 1,
        senderId: 'user1',
        content: 'Message 1',
        createdAt: DateTime.now(),
        roomId: roomId,
      );
      controller.add([message1]);
      await pumpEventQueue();

      expect(
        notifier.debugState,
        isA<AsyncData<List<ChatMessage>>>()
            .having((d) => d.value, 'messages', [message1]),
      );

      // Send second message
      final message2 = ChatMessage(
        id: 2,
        senderId: 'user1',
        content: 'Message 2',
        createdAt: DateTime.now(),
        roomId: roomId,
      );
      controller.add([message1, message2]);
      await pumpEventQueue();

      expect(
        notifier.debugState,
        isA<AsyncData<List<ChatMessage>>>()
            .having((d) => d.value.length, 'messages length', 2),
      );

      await controller.close();
    });

    test('should handle errors', () async {
      final controller = StreamController<List<ChatMessage>>.broadcast();
      when(mockRepository.getMessages(roomId))
          .thenAnswer((_) => controller.stream);

      notifier = MessagesNotifier(mockRepository, roomId);
      await pumpEventQueue();

      final error = Exception('Test error');
      controller.addError(error);
      await pumpEventQueue();

      expect(
        notifier.debugState,
        isA<AsyncError<List<ChatMessage>>>()
            .having((e) => e.error, 'error', error),
      );

      await controller.close();
    });
  });
}