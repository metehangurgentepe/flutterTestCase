
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoggingService {
  final SupabaseClient _supabase;
  final Logger _logger = Logger();

  LoggingService(this._supabase);

  Future<void> logToDatabase(String level, String message) async {
    try {
      await _supabase.from('logs').insert({
        'level': level,
        'message': message,
      });
    } catch (e) {
      _logger.e('Error logging to database', e);
    }
  }

  void logError(String message, dynamic error) {
    _logger.e(message, error);
    logToDatabase('error', '$message: $error');
  }

  void logInfo(String message) {
    _logger.i(message);
    logToDatabase('info', message);
  }

  void logWarning(String message) {
    _logger.w(message);
    logToDatabase('warning', message);
  }
}