import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/auth_notifier.dart';
import 'package:test_case/features/chat/provider/chat_provider.dart';
import '../model/user_model.dart';
import '../repository/providers.dart';
import 'package:test_case/features/notifications/service/notification_service.dart';

final notificationServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationService(supabase, ref);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return AuthNotifier(repository, ref.read, notificationService);
});

