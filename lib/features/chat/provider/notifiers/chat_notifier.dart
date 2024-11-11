import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/repository/chat_room_repository.dart';

class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final IChatRoomRepository _repository;

  ChatNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> sendMessage(ChatMessage message) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendMessage(message);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}