
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseInit {
  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
        debug: true,
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 10,
          logLevel: RealtimeLogLevel.info, 
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  static SupabaseClient get instance {
    try {
      return Supabase.instance.client;
    } catch (e) {
      rethrow;
    }
  }
}