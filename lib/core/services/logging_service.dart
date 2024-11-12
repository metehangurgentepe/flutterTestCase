import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  
  final Logger _logger = Logger();
  SupabaseClient? _supabase;

  LoggingService._internal();

  // Rename initialize to setSupabaseClient for clarity
  void setSupabaseClient(SupabaseClient supabase) {
    _supabase = supabase;
  }

  Future<void> _logToDatabase(String level, String message) async {
    if (_supabase == null) return;
    
    try {
      await _supabase!.from('logs').insert({
        'level': level,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Failed to log to database', e);
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
    _logToDatabase('ERROR', '$message ${error ?? ''} ${stackTrace ?? ''}');
  }

  void info(String message) {
    _logger.i(message);
    _logToDatabase('INFO', message);
  }

  void warning(String message) {
    _logger.w(message);
    _logToDatabase('WARNING', message);
  }

  void debug(String message) {
    if (kDebugMode) {
      _logger.d(message);
      _logToDatabase('DEBUG', message);
    }
  }

  // Add alias for backward compatibility
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    error(message, error, stackTrace);
  }

  // Alias for backward compatibility
  void initialize(SupabaseClient supabase) {
    setSupabaseClient(supabase);
  }
}