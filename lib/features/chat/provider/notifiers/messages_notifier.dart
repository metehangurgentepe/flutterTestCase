import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/repository/chat_repository.dart';

class MessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final IChatRepository _repository;
  final String roomId;
  StreamSubscription<List<ChatMessage>>? _subscription;

  MessagesNotifier(this._repository, this.roomId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await loadMessages();
      
      _subscription = _repository.getMessages(roomId).listen(
        (messages) {
          if (mounted) {
            state = AsyncValue.data(messages);
          }
        },
        onError: (error, stack) {
          if (mounted) {
            state = AsyncValue.error(error, stack);
          }
        },
      );
    } catch (error) {
      if (mounted) {
        state = AsyncValue.error(error, StackTrace.current);
      }
    }
  }

  Future<void> sendMessage(String content) async {
    try {
      final message = ChatMessage(
        id: null,
        senderId: _repository.currentUserId ?? '',
        content: content,
        createdAt: DateTime.now(),
        roomId: roomId,
      );

      await _repository.sendMessage(message);
      
      await loadMessages();
    } catch (error) {
      if (mounted) {
        state = AsyncValue.error(error, StackTrace.current);
      }
    }
  }

  Future<void> loadMessages() async {
    try {
      final messages = await _repository.getMessages(roomId).first;
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (error, stack) {
      if (mounted) {
        state = AsyncValue.error(error, stack);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
