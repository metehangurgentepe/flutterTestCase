import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/features/home/repository/chat_repository.dart';

class HomeNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repository;

  HomeNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<ChatRoom> createChatRoom(ChatRoom room) async {
    state = const AsyncValue.loading();
    try {
      final createdRoom = await _repository.createChatRoom(room);
      state = const AsyncValue.data(null);
      return createdRoom;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> createGroupRoom(String name, List<String> memberIds) async {
    state = const AsyncValue.loading();
    try {
      final chatRoom = ChatRoom(
        name: name,
        isGroup: true,
        participants: memberIds,
        createdAt: DateTime.now(),
        lastMessage: null,
        lastMessageTime: null,
        imageUrl: null,
      );
      await _repository.createChatRoom(chatRoom);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
