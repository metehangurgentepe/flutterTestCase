import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/models/user_presence.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';

import 'chat_repository_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  RealtimeChannel,
  PostgrestFilterBuilder,
])
void main() {
  group('ChatMessage Tests', () {
    test('should create ChatMessage from json', () {
      final json = {
        'id': '1',
        'user_id': 'user123',
        'content': 'Hello',
        'created_at': '2024-01-01T12:00:00Z',
        'room_id': 'room123'
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, equals(1));
      expect(message.senderId, equals('user123'));
      expect(message.content, equals('Hello'));
      expect(message.roomId, equals('room123'));
      expect(
        message.createdAt.toIso8601String(),
        equals('2024-01-01T12:00:00.000Z'),
      );
    });

    test('should convert ChatMessage to json', () {
      final message = ChatMessage(
        id: 1,
        senderId: 'user123',
        content: 'Hello',
        createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
        roomId: 'room123',
      );

      final json = message.toJson();

      expect(json['id'], equals('1'));
      expect(json['user_id'], equals('user123'));
      expect(json['content'], equals('Hello'));
      expect(json['room_id'], equals('room123'));
      expect(
        json['created_at'],
        equals('2024-01-01T12:00:00.000Z'),
      );
    });

    test('should handle null id in json conversion', () {
      final message = ChatMessage(
        id: null,
        senderId: 'user123',
        content: 'Hello',
        createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
        roomId: 'room123',
      );

      final json = message.toJson();

      expect(json.containsKey('id'), isFalse);
    });
  });
}