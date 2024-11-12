import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/home/view/home_view.dart';
import 'login_view.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        print('AuthWrapper: Current user state - ${user?.toJson()}');
        if (user != null) {
          return const HomeView();
        }
        return const LoginView();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) {
        print('AuthWrapper: Error - $error');
        return const LoginView();
      },
    );
  }
}