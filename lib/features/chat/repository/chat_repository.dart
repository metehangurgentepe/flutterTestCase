import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/utils/helpers/cache_manager.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/model/chat_room_model.dart';

class ChatRoomCreationException implements Exception {
  final String message;
  final dynamic error;
  ChatRoomCreationException(this.message, this.error);
}

class ProfileFetchException implements Exception {
  final String message;
  final dynamic error;
  ProfileFetchException(this.message, this.error);
}

class MessageSendException implements Exception {
  final String message;
  final dynamic error;
  MessageSendException(this.message, this.error);
}

abstract class IChatRepository {
  String? get currentUserId;
  Stream<List<ChatRoom>> getChatRooms(String userId);
  Stream<List<ChatMessage>> getMessages(String roomId);
  Stream<List<UserModel>> getUsers(String query);
  Future<void> sendMessage(ChatMessage message);
  Future<ChatRoom> createChatRoom(ChatRoom room);
  Future<void> markAsRead(String messageId);
  Stream<List<ChatRoom>> getGroupRooms(String userId);
  Stream<List<ChatRoom>> getChatRoomsStream(String userId);

}

class ChatRepository implements IChatRepository {
  final SupabaseClient _supabase;
  final CacheManager _cache;
  final Map<String, RealtimeChannel> _channels = {};

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  ChatRepository(this._supabase) : _cache = CacheManager();

  Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    final cacheKey = 'profile_$userId';
    
    try {
      if (_cache.hasValid(cacheKey)) {
        return _cache.get<Map<String, dynamic>>(cacheKey)!;
      }

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      _cache.set(cacheKey, profile);
      return profile;
    } catch (e) {
      throw ProfileFetchException('Failed to fetch user profile', e);
    }
  }

  @override
  Stream<List<ChatRoom>> getChatRoomsStream(String userId) {
    return _supabase
        .from('chat_rooms')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .map((data) => data.map((room) => ChatRoom.fromJson(room)).toList());
  }

  @override
  Future<ChatRoom> createChatRoom(ChatRoom room) async {
    try {
      if (!room.isGroup && room.participants.length == 2) {
        final existingRoom = await findExistingChatRoom(
            room.participants[0], room.participants[1]);

        if (existingRoom != null) {
          return existingRoom;
        }
      }

      final roomData = {
        'name': room.name,
        'is_group': room.isGroup,
        'participants': room.participants,
        'created_at': DateTime.now().toIso8601String(),
        'last_message': null,
        'last_message_time': null,
        'image_url': room.imageUrl,
      };

      final response =
          await _supabase.from('chat_rooms').insert(roomData).select().single();

      for (final userId in room.participants) {
        if (room.isGroup) {
          _cache.remove('group_rooms_$userId');
        } else {
          _cache.remove('rooms_$userId');
        }
      }

      return ChatRoom.fromJson(response);
    } catch (e) {
      throw ChatRoomCreationException('Failed to create chat room', e);
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

              profileFutures.add(_getUserProfile(otherUserId).then((otherUserProfile) {
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
                errorMessages.add('Failed to fetch profile for user $otherUserId: $e');
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

  @override
  Stream<List<ChatRoom>> getGroupRooms(String userId) {
    final cacheKey = 'group_rooms_$userId';

    if (_cache.hasValid(cacheKey)) {
      return Stream.value(_cache.get<List<ChatRoom>>(cacheKey)!);
    }

    return _supabase
        .from('chat_rooms')
        .stream(primaryKey: ['id'])
        .eq('is_group', true)
        .order('created_at', ascending: false)
        .map((data) async {
          final List<ChatRoom> rooms = [];

          for (final json in data) {
            try {
              rooms.add(ChatRoom(
                id: json['id'],
                name: json['name'],
                isGroup: true,
                lastMessage: json['last_message'],
                lastMessageTime: json['last_message_time'] != null
                    ? DateTime.parse(json['last_message_time'])
                    : null,
                imageUrl: json['image_url'],
                createdAt: DateTime.parse(json['created_at']),
                participants: List<String>.from(json['participants']),
              ));
            } catch (e) {
              throw MessageSendException('Failed to fetch group rooms', e);
            }
          }

          return rooms;
        })
        .asyncMap((futureRooms) async {
          final rooms = await futureRooms;
          _cache.set(cacheKey, rooms);
          return rooms;
        });
  }

  Future<ChatRoom?> findExistingChatRoom(String user1Id, String user2Id) async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select()
          .eq('is_group', false)
          .contains('participants', [user1Id, user2Id])
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return ChatRoom(
        id: response['id'],
        name: response['name'],
        isGroup: response['is_group'],
        lastMessage: response['last_message'],
        lastMessageTime: response['last_message_time'] != null
            ? DateTime.parse(response['last_message_time'])
            : null,
        imageUrl: response['image_url'],
        createdAt: DateTime.parse(response['created_at']),
        participants: response['participants']?.cast<String>(),
      );
    } catch (e) {
      return null;
    }
  }

   @override
  Stream<List<ChatMessage>> getMessages(String roomId) {
    if (!_channels.containsKey(roomId)) {
      final channel = _supabase.channel('room-$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            _invalidateMessageCache(roomId);
            _refreshMessages(roomId);
          },
        )
        .subscribe();

      _channels[roomId] = channel;
    }

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map((data) {
          final messages = data
              .map((json) => ChatMessage.fromJson(json))
              .toList();
          _cache.set('messages_$roomId', messages);
          return messages;
        });
  }

  Future<void> _refreshMessages(String roomId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false);

      final messages = response
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      _cache.set('messages_$roomId', messages);
    } catch (e) {
       throw MessageSendException('Failed to send message', e);
    }
  }

  void _invalidateMessageCache(String roomId) {
    _cache.remove('messages_$roomId');
  }

  @override
  Stream<List<UserModel>> getUsers(String searchQuery) {
    final cacheKey = 'users_$searchQuery';

    if (_cache.hasValid(cacheKey)) {
      return Stream.value(_cache.get<List<UserModel>>(cacheKey)!);
    }

    return Stream.fromFuture(_supabase
        .from('profiles')
        .select()
        .ilike('username', '%$searchQuery%')
        .then((data) {
          final users = (data as List)
              .map((json) => UserModel.fromJson(json))
              .toList();
          _cache.set(cacheKey, users);
          return users;
        }));
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    try {
      await _supabase
          .from('messages')
          .insert(message.toJson());

      await _supabase
          .from('chat_rooms')
          .update({
            'last_message': message.content,
            'last_message_time': message.createdAt.toIso8601String(),
          })
          .eq('id', message.roomId);

      final roomDetails = await _supabase
          .from('chat_rooms')
          .select()
          .eq('id', message.roomId)
          .single();

      if (roomDetails['is_group'] == true) {
        final keys = _cache.getKeys().where((key) => key.startsWith('group_rooms_'));
        for (final key in keys) {
          _cache.remove(key);
        }
      } else {
        final participants = List<String>.from(roomDetails['participants']);
        for (final userId in participants) {
          _cache.remove('rooms_$userId');
        }
      }
      
      _cache.remove('messages_${message.roomId}');
    } catch (e) {
      throw MessageSendException('Failed to send message', e);
    }
  }

  void clearCache() {
    _cache.clear();
  }

  void _invalidateProfileCache(String userId) {
    _cache.remove('profile_$userId');
  }

  @override
  Future<void> markAsRead(String messageId) async {
    await _supabase
        .from('messages')
        .update({'is_read': true}).eq('id', messageId);
  }

  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}
