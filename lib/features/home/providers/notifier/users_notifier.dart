

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/home/repository/chat_repository.dart';

class UsersNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final IChatRepository _repository;
  final String query;
  StreamSubscription<List<UserModel>>? _subscription;

  UsersNotifier(this._repository, this.query) : super(const AsyncValue.loading()) {
    _initializeUsers();
  }

  void _initializeUsers() {
    _subscription?.cancel();
    state = const AsyncValue.loading();

    _subscription = _repository.getUsers(query).listen(
      (users) {
        if (!mounted) return;
        state = AsyncValue.data(users);
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