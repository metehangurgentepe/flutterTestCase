import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/view/chat_list_view.dart';
import '../providers/auth_providers.dart';
import 'login_view.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const ChatListView();
        }
        return const LoginView();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(authStateProvider.notifier).resetState();
        });
        return const LoginView();
      },
    );
  }
}