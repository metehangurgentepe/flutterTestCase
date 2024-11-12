import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/errors/chat_exceptions.dart';
import 'package:test_case/core/utils/helpers/cache_manager.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';

abstract class IChatRoomRepository {
  String? get currentUserId;
  Stream<List<ChatMessage>> getMessages(String roomId);
  Future<void> sendMessage(ChatMessage message);
  Future<void> markAsRead(String messageId);
  Future<Map<String, dynamic>> getUserProfile(String userId);
  Stream<List<ChatRoom>> getChatRooms(String userId);
}

class ChatRoomRepository implements IChatRoomRepository {
  final SupabaseClient _supabase;
  final CacheManager _cache;
  final Map<String, RealtimeChannel> _channels = {};

  ChatRoomRepository(this._supabase) : _cache = CacheManager();

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  Stream<List<ChatMessage>> getMessages(String roomId) {
    _setupRealtimeSubscription(roomId);
    return _getMessagesStream(roomId);
  }

  void _setupRealtimeSubscription(String roomId) {
    if (_channels.containsKey(roomId)) return;

    final channel = _supabase.channel('room-$roomId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (_) => _invalidateCache(roomId),
      ).subscribe();

    _channels[roomId] = channel;
  }

  Stream<List<ChatMessage>> _getMessagesStream(String roomId) {
    final cacheKey = 'messages_$roomId';
    
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((data) => _processMessages(data, cacheKey));
  }

  List<ChatMessage> _processMessages(List<dynamic> data, String cacheKey) {
    final messages = data.map((json) => ChatMessage.fromJson(json)).toList();
    _cache.set(cacheKey, messages);
    return messages;
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    try {
      await _supabase.from('messages').insert(message.toJson());
      await _updateLastMessage(message);
      _invalidateCache(message.roomId);
    } catch (e) {
      throw MessageSendException('Failed to send message', e);
    }
  }

  Future<void> _updateLastMessage(ChatMessage message) async {
    await _supabase.from('chat_rooms').update({
      'last_message': message.content,
      'last_message_time': message.createdAt.toIso8601String(),
    }).eq('id', message.roomId);
  }

  void _invalidateCache(String roomId) {
    _cache.remove('messages_$roomId');
  }

  @override
  Future<void> markAsRead(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      throw MessageUpdateException('Failed to mark message as read', e);
    }
  }

  @override
  void dispose() {
    _channels.values.forEach((channel) => channel.unsubscribe());
    _channels.clear();
    _cache.clear();
  }

  @override
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final cacheKey = 'profile_$userId';

    try {
      if (_cache.hasValid(cacheKey)) {
        return _cache.get<Map<String, dynamic>>(cacheKey)!;
      }

      final profile =
          await _supabase.from('profiles').select().eq('id', userId).single();

      _cache.set(cacheKey, profile);
      return profile;
    } catch (e) {
      throw ProfileFetchException('Failed to fetch user profile', e);
    }
  }

  Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    final cacheKey = 'profile_$userId';

    try {
      if (_cache.hasValid(cacheKey)) {
        return _cache.get<Map<String, dynamic>>(cacheKey)!;
      }

      final profile =
          await _supabase.from('profiles').select().eq('id', userId).single();

      _cache.set(cacheKey, profile);
      return profile;
    } catch (e) {
      throw ProfileFetchException('Failed to fetch user profile', e);
    }
  }

  @override
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    final cacheKey = 'rooms_$userId';

    if (_cache.hasValid(cacheKey)) {
      return Stream.value(_cache.get<List<ChatRoom>>(cacheKey)!);
    }

    return _supabase
        .from('chat_rooms')
        .stream(primaryKey: ['id'])
        .eq('is_group', false)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final List<ChatRoom> rooms = [];
          final List<Future<void>> profileFutures = [];
          final List<String> errorMessages = [];

          for (final json in data) {
            try {
              final otherUserId = (json['participants'] as List)
                  .cast<String>()
                  .firstWhere((id) => id != userId);

              profileFutures
                  .add(_getUserProfile(otherUserId).then((otherUserProfile) {
                rooms.add(ChatRoom(
                  id: json['id'],
                  name: otherUserProfile['username'],
                  isGroup: false,
                  lastMessage: json['last_message'],
                  lastMessageTime: json['last_message_time'] != null
                      ? DateTime.parse(json['last_message_time'])
                      : null,
                  imageUrl: otherUserProfile['avatar_url'],
                  createdAt: DateTime.parse(json['created_at']),
                  participants: List<String>.from(json['participants']),
                ));
              }).catchError((e) {
                errorMessages
                    .add('Failed to fetch profile for user $otherUserId: $e');
              }));
            } catch (e) {
              errorMessages.add('Error processing chat room data: $e');
            }
          }

          await Future.wait(profileFutures);

          if (errorMessages.isNotEmpty) {
            errorMessages.forEach(print);
          }

          rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _cache.set(cacheKey, rooms);
          return rooms;
        });
  }

  Future<void> _refreshMessages(String roomId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false);

      final messages =
          response.map((json) => ChatMessage.fromJson(json)).toList();
      _cache.set('messages_$roomId', messages);
    } catch (e) {
      throw MessageSendException('Failed to refresh messages', e);
    }
  }

  void _invalidateMessageCache(String roomId) {
    _cache.remove('messages_$roomId');
  }
}
