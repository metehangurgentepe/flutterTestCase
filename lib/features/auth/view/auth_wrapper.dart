import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/home/view/home_view.dart';
import 'login_view.dart';
import 'package:test_case/core/services/logger_service.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  final _logger = LoggerService();

  @override
  void initState() {
    super.initState();
    // Check auth status when widget initializes
    Future.microtask(() {
      ref.read(authStateProvider.notifier).checkAuthStatus();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        _logger.info('Auth state changed: ${user?.toJson()}');
        if (user != null) {
          return const HomeView();
        }
        return const LoginView();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        _logger.error('Auth state error', error, stack);
        return const LoginView();
      },
    );
  }
}