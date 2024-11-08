import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/model/chat_room_model.dart';
import 'package:test_case/features/chat/repository/chat_repository.dart';

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final IChatRepository _repository;
  final String userId;
  StreamSubscription? _roomsSubscription;

  ChatRoomsNotifier(this._repository, this.userId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await refreshRooms();

      _roomsSubscription = _repository.getChatRoomsStream(userId).listen(
        (rooms) {
          if (mounted) {
            state = AsyncValue.data(rooms);
          }
        },
        onError: (error) {
          if (mounted) {
            state = AsyncValue.error(error, StackTrace.current);
          }
        },
      );
    } catch (error, stack) {
      if (mounted) {
        state = AsyncValue.error(error, stack);
      }
    }
  }

  Future<void> refreshRooms() async {
    try {
      final rooms = await _repository.getChatRoomsStream(userId).first; // Changed from getChatRooms to getChatRoomsStream().first
      if (mounted) {
        state = AsyncValue.data(rooms);
      }
    } catch (error, stack) {
      if (mounted) {
        state = AsyncValue.error(error, stack);
      }
    }
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    super.dispose();
  }
}

class GroupRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final IChatRepository _repository;
  final String userId;
  StreamSubscription<List<ChatRoom>>? _subscription;

  GroupRoomsNotifier(this._repository, this.userId) : super(const AsyncValue.loading()) {
    _initializeGroupRooms();
  }

  void _initializeGroupRooms() {
    _subscription?.cancel();
    state = const AsyncValue.loading();
    _subscription = _repository.getGroupRooms(userId).listen(
      (rooms) {
        if (!mounted) return;
        state = AsyncValue.data(rooms);
      },
      onError: (error, stack) {
        if (!mounted) return;
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}