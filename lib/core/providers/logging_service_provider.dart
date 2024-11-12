
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/services/logging_service.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';

final loggingServiceProvider = Provider<LoggingService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LoggingService(supabase);
});