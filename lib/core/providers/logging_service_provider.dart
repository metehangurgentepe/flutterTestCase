
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/services/logging_service.dart';

final loggingServiceProvider = Provider<LoggingService>((ref) {
  return LoggingService();
});