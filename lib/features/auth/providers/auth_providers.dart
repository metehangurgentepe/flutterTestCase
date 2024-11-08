import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/auth_notifier.dart';
import '../model/user_model.dart';
import '../repository/providers.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref.read);
});

