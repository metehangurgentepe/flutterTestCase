import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_case/features/auth/view/auth_wrapper.dart';
import 'package:test_case/features/chat/view/chat_view.dart';

enum AppRoute {
  home('/'),
  chat('/chat/:roomId');

  final String path;
  const AppRoute(this.path);
}

final class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoute.home.path,
        builder: (context, state) => const AuthWrapper(),
      ),
      GoRoute(
        path: AppRoute.chat.path,
        builder: (context, state) => ChatRoomView(
          roomId: state.pathParameters['roomId']!,
          roomName: state.extra as String,
        ),
      ),
    ],
  );
}