
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/provider/chat_provider.dart';
import 'package:test_case/features/notifications/service/notification_service.dart';

final notificationServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationService(supabase, ref);
});