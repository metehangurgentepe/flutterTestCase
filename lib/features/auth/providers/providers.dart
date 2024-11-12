import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/providers/logging_service_provider.dart';
import 'package:test_case/core/services/auth_service.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/notifiers/auth_notifier.dart';
import 'package:test_case/features/auth/repository/profile_repository.dart';
import 'package:test_case/features/chat/provider/chat_room_providers.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/core/notifications/service/notification_service.dart';
import '../repository/auth_repository.dart';


final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  
  return AuthRepository(
    supabase,
    notificationService,
    profileRepository,
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProfileRepository(supabase);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  return NotificationService(supabase, loggingService);
});

final authServiceProvider = Provider<IAuthService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final presenceService = ref.watch(presenceServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return AuthService(repository, presenceService, notificationService);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});