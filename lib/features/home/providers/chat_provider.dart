import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/home/providers/notifier/users_notifier.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/features/home/providers/chat_rooms_notifier.dart';
import 'package:test_case/features/home/providers/notifier/home_notifier.dart';
import 'package:test_case/features/home/repository/chat_repository.dart';
import 'package:test_case/core/providers/supabase_provider.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ChatRepository(supabase);
});

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

final chatListProvider =
    StateNotifierProvider<HomeNotifier, AsyncValue<void>>((ref) {
  return HomeNotifier(ref.watch(chatRepositoryProvider));
});

final usersProvider = StateNotifierProvider.family<UsersNotifier,
    AsyncValue<List<UserModel>>, String>(
  (ref, query) => UsersNotifier(
    ref.watch(chatRepositoryProvider),
    query,
  ),
);
