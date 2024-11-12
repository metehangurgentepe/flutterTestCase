import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logging_service.dart';

@Deprecated('Use LoggingService instead')
class LoggerService {
  final _loggingService = LoggingService();

  void initialize(SupabaseClient supabase) {
    _loggingService.setSupabaseClient(supabase);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _loggingService.error(message, error, stackTrace);
  }

  void info(String message) {
    _loggingService.info(message);
  }

  void warning(String message) {
    _loggingService.warning(message);
  }

  void debug(String message) {
    _loggingService.debug(message);
  }
}