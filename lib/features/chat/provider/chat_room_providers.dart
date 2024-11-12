import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/models/user_presence.dart';
import 'package:test_case/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/services/chat_room_service.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/provider/notifiers/chat_notifier.dart';
import 'package:test_case/features/chat/provider/notifiers/messages_notifier.dart';
import 'package:test_case/features/chat/repository/chat_room_repository.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';

// final userProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
//   final chatRoomService = ref.watch(chatRoomServiceProvider);
//   return await chatRoomService.getUserProfile(userId);
// });

final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    AsyncValue<List<ChatMessage>>, String>((ref, roomId) {
  return MessagesNotifier(
    ref.watch(chatRoomRepositoryProvider),
    roomId,
  );
});

final roomProvider =
    FutureProvider.family<ChatRoom, String>((ref, roomId) async {
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
        name: userResult['username'] ?? 'Unknown User',
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

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final supabase = Supabase.instance.client;
  return PresenceService(supabase);
});

final userPresenceProvider =
    StreamProvider.family<UserPresence, String>((ref, userId) {
  final presenceService = ref.watch(presenceServiceProvider);
  return presenceService
      .getUserPresenceFromDB(userId)
      .map((data) => UserPresence.fromJson(data));
});

final otherUserIdProvider =
    FutureProvider.family<String?, String>((ref, roomId) async {
  final room = await ref.watch(roomProvider(roomId).future);
  final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

  if (currentUserId == null || room.isGroup) return null;

  return room.participants.firstWhere(
    (id) => id != currentUserId,
    orElse: () => '',
  );
});

final chatProvider = StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier(ref.watch(chatRoomRepositoryProvider));
});

final chatRoomServiceProvider = Provider<ChatRoomService>((ref) {
  return ChatRoomService(ref.read(chatRoomRepositoryProvider));
});

final chatRoomRepositoryProvider = Provider<IChatRoomRepository>((ref) {
  final supabaseClient = ref.read(supabaseProvider);
  return ChatRoomRepository(supabaseClient);
});

