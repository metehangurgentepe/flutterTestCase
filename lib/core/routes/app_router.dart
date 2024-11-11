import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_case/core/routes/app_routes.dart';
import 'package:test_case/features/auth/view/auth_wrapper.dart';
import 'package:test_case/features/chat/view/chat_view.dart';

final class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
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