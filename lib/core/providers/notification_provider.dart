
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/notifications/service/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = Supabase.instance.client;
  return NotificationService(supabase, ref);
});
