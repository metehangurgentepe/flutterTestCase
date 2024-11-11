import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/models/user_presence.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/model/chat_room_model.dart';
import 'package:test_case/features/chat/provider/notifiers/chat_notifier.dart';
import 'package:test_case/features/chat/provider/notifiers/chat_rooms_notifier.dart';
import 'package:test_case/features/chat/provider/notifiers/messages_notifier.dart';
import 'package:test_case/features/chat/provider/notifiers/users_notifier.dart';
import 'package:test_case/features/chat/repository/chat_repository.dart';
import 'package:test_case/core/providers/supabase_provider.dart';
import 'package:test_case/features/notifications/service/notification_service.dart';

/// Core Providers
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ChatRepository(supabase);
});

/// Service Providers
final presenceServiceProvider = Provider<PresenceService>((ref) {
  final supabase = Supabase.instance.client;
  return PresenceService(supabase);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationService(supabase, ref);
});

/// Chat Room Providers
final chatRoomsProvider = StateNotifierProvider.family<ChatRoomsNotifier,
    AsyncValue<List<ChatRoom>>, String>(
  (ref, userId) => ChatRoomsNotifier(
    ref.watch(chatRepositoryProvider),
    userId,
  ),
);

final groupRoomsProvider = StateNotifierProvider.family<GroupRoomsNotifier,
    AsyncValue<List<ChatRoom>>, String>(
  (ref, userId) => GroupRoomsNotifier(
    ref.watch(chatRepositoryProvider),
    userId,
  ),
);

final chatRoomsStreamProvider = StreamProvider.family<List<ChatRoom>, String>((ref, userId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatRoomsStream(userId);
});

final roomProvider = FutureProvider.family<ChatRoom, String>((ref, roomId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final currentUserId = supabase.auth.currentUser?.id;

  if (currentUserId == null) {
    throw Exception('No authenticated user');
  }

  final result = await supabase
      .from('chat_rooms')
      .select(
          'id, name, last_message, last_message_time, is_group, image_url, created_at, participants')
      .eq('id', roomId)
      .single();

  final chatRoom = ChatRoom.fromJson(result);

  // Birebir sohbet ise
  if (!chatRoom.isGroup) {
    final otherUserId = chatRoom.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isNotEmpty) {
      final userResult = await supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', otherUserId)
          .single();

      return ChatRoom(
        id: chatRoom.id,
        name:
            userResult['username'] ?? 'Unknown User',
        lastMessage: chatRoom.lastMessage,
        lastMessageTime: chatRoom.lastMessageTime,
        isGroup: chatRoom.isGroup,
        imageUrl: chatRoom.imageUrl ?? userResult['avatar_url'],
        createdAt: chatRoom.createdAt,
        participants: chatRoom.participants,
      );
    }
  }

  return chatRoom;
});

final roomParticipantsProvider = FutureProvider.family<List<String>, String>((ref, roomId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final result = await supabase
      .from('chat_rooms')
      .select('participants, is_group')
      .eq('id', roomId)
      .single();

  final List<dynamic> participants = result['participants'] ?? [];
  return participants.cast<String>().toList();
});

final isGroupChatProvider = FutureProvider.family<bool, String>((ref, roomId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final result = await supabase
      .from('chat_rooms')
      .select('is_group')
      .eq('id', roomId)
      .single();
  return result['is_group'] ?? false;
});

/// Message Providers
final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    AsyncValue<List<ChatMessage>>, String>((ref, roomId) {
  return MessagesNotifier(
    ref.watch(chatRepositoryProvider),
    roomId,
  );
});

/// User Providers
final usersProvider = StateNotifierProvider.family<UsersNotifier,
    AsyncValue<List<UserModel>>, String>(
  (ref, query) => UsersNotifier(
    ref.watch(chatRepositoryProvider),
    query,
  ),
);

final userPresenceProvider = StreamProvider.family<UserPresence, String>((ref, userId) {
  final presenceService = ref.watch(presenceServiceProvider);
  return presenceService
      .getUserPresenceFromDB(userId)
      .map((data) => UserPresence.fromJson(data));
});

final userProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final result = await supabase
      .from('profiles')
      .select('username, avatar_url')
      .eq('id', userId)
      .single();

  return {
    'username': result['username'],
    'avatarUrl': result['avatar_url'],
    'displayName': result['username'] ?? 'Unknown User', // Sadece username
  };
});

final otherUserIdProvider = FutureProvider.family<String?, String>((ref, roomId) async {
  final room = await ref.watch(roomProvider(roomId).future);
  final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

  if (currentUserId == null || room.isGroup) return null;

  return room.participants.firstWhere(
    (id) => id != currentUserId,
    orElse: () => '',
  );
});

/// Chat Operations Provider
final chatProvider = StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier(ref.watch(chatRepositoryProvider));
});
