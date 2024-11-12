import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/errors/chat_exceptions.dart';
import 'package:test_case/core/utils/helpers/cache_manager.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';

abstract class IChatRepository {
  String? get currentUserId;
  Stream<List<ChatRoom>> getChatRooms(String userId);
  Stream<List<UserModel>> getUsers(String query);
  Future<ChatRoom> createChatRoom(ChatRoom room);
  Stream<List<ChatRoom>> getGroupRooms(String userId);
  Stream<List<ChatRoom>> getChatRoomsStream(String userId);
}

class ChatRepository implements IChatRepository {
  final SupabaseClient _supabase;
  final CacheManager _cache;
  final Map<String, RealtimeChannel> _channels = {};

  ChatRepository(this._supabase) : _cache = CacheManager();

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Extract profile fetching logic to a separate method
  @override
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _withCache('profile_$userId', () async {
      final profile = await _supabase.from('profiles').select().eq('id', userId).single();
      return profile;
    });
  }

  // Generic cache wrapper
  Future<T> _withCache<T>(String key, Future<T> Function() fetchData) async {
    if (_cache.hasValid(key)) {
      return _cache.get<T>(key)!;
    }

    final data = await fetchData();
    _cache.set(key, data);
    return data;
  }

  @override
  Stream<List<ChatRoom>> getChatRoomsStream(String userId) {
    return _supabase
        .from('chat_rooms')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .map(_mapToChatRooms);
  }

  List<ChatRoom> _mapToChatRooms(List<Map<String, dynamic>> data) {
    return data.map((room) => ChatRoom.fromJson(room)).toList();
  }

  @override
  Future<ChatRoom> createChatRoom(ChatRoom room) async {
    try {
      if (!room.isGroup && room.participants.length == 2) {
        final existingRoom = await _findExistingPersonalChat(room.participants);
        if (existingRoom != null) return existingRoom;
      }

      final roomData = _prepareChatRoomData(room);
      final response = await _supabase.from('chat_rooms').insert(roomData).select().single();
      _invalidateRoomCaches(room);

      return ChatRoom.fromJson(response);
    } catch (e) {
      throw ChatRoomCreationException('Failed to create chat room', e);
    }
  }

  Map<String, dynamic> _prepareChatRoomData(ChatRoom room) {
    return {
      'name': room.name,
      'is_group': room.isGroup,
      'participants': room.participants,
      'created_at': DateTime.now().toIso8601String(),
      'last_message': null,
      'last_message_time': null,
      'image_url': room.imageUrl,
    };
  }

  void _invalidateRoomCaches(ChatRoom room) {
    for (final userId in room.participants) {
      _cache.remove(room.isGroup ? 'group_rooms_$userId' : 'rooms_$userId');
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
                  .add(getUserProfile(otherUserId).then((otherUserProfile) {
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
        .map((data) {
          final List<ChatRoom> rooms = [];

          for (final json in data) {
            try {
              rooms.add(ChatRoom(
                id: json['id'],
                // Direkt olarak json'dan gelen name'i kullan, null değilse
                name: json['name'] ?? 'Unnamed Group',
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
              print('Error processing group room: $e');
            }
          }

          return rooms;
        });
  }

  Future<ChatRoom?> _findExistingPersonalChat(List<String> participants) async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select()
          .eq('is_group', false)
          .contains('participants', participants)
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
      final users =
          (data as List).map((json) => UserModel.fromJson(json)).toList();
      _cache.set(cacheKey, users);
      return users;
    }));
  }

  void clearCache() {
    _cache.clear();
  }

  void _invalidateProfileCache(String userId) {
    _cache.remove('profile_$userId');
  }

  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}
