
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/providers/logging_service_provider.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/core/notifications/service/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  return NotificationService(supabase, loggingService);
});