import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/features/home/providers/notifier/users_notifier.dart';
import 'package:test_case/features/home/providers/notifier/home_notifier.dart';
import 'package:test_case/features/home/providers/chat_rooms_notifier.dart';
import 'package:test_case/features/home/repository/chat_repository.dart';
import 'package:test_case/core/providers/supabase_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ChatRepository(supabase);
});

final chatRoomsProvider = StateNotifierProvider.family<ChatRoomsNotifier,
    AsyncValue<List<ChatRoom>>, String>(
  (ref, userId) => ChatRoomsNotifier(ref.watch(chatRepositoryProvider), userId),
);

final groupRoomsProvider = StateNotifierProvider.family<GroupRoomsNotifier,
    AsyncValue<List<ChatRoom>>, String>(
  (ref, userId) =>
      GroupRoomsNotifier(ref.watch(chatRepositoryProvider), userId),
);

final usersProvider = StateNotifierProvider.family<UsersNotifier,
    AsyncValue<List<UserModel>>, String>(
  (ref, query) => UsersNotifier(ref.watch(chatRepositoryProvider), query),
);

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final chatListProvider =
    StateNotifierProvider<HomeNotifier, AsyncValue<void>>((ref) {
  return HomeNotifier(ref.watch(chatRepositoryProvider));
});

final userProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  if (userId.isEmpty) return null;
  final repository = ref.watch(chatRepositoryProvider);
  try {
    final profile = await repository.getUserProfile(userId);
    return UserModel.fromJson(profile);
  } catch (e) {
    return null;
  }
});
