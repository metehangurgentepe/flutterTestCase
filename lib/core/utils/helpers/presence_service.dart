import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/services/logger_service.dart';

class PresenceService {
  final SupabaseClient _supabase;
  final _channel = 'user_presence';
  RealtimeChannel? _presenceChannel;
  final _logger = LoggerService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  PresenceService(this._supabase) {
    if (_supabase.auth.currentUser != null) {
      initializePresence();
    }
  }

  Future<void> initializePresence() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      await _presenceChannel?.unsubscribe();
      _presenceChannel = null;

      final now = DateTime.now().toIso8601String();

      await _supabase.from('user_presence').upsert({
        'user_id': userId,
        'status': 'online',
        'last_seen': now,
      }, onConflict: 'user_id');

      final channel = _supabase.channel(_channel);

      channel.onPresenceSync((payload) {
        _logger.info('Presence sync: $payload');
      }).onPresenceJoin((payload) {
        _logger.info('User joined: $payload');
      }).onPresenceLeave((payload) {
        _logger.info('User left: $payload');
      });

      final status = await channel.subscribe();
      if (status == 'SUBSCRIBED') {
        await channel
            .track({'user_id': userId, 'online_at': now, 'status': 'online'});
        _presenceChannel = channel;
        _isInitialized = true;
      } else {
        _isInitialized = false;
      }
    } catch (e, stack) {
      _logger.error('Error initializing presence', e, stack);
      _isInitialized = false;
    }
  }

  Future<void> updateStatus(String status) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final timestamp = DateTime.now().toIso8601String();

      await _supabase.from('user_presence').upsert({
        'user_id': userId,
        'status': status,
        'last_seen': timestamp,
      }, onConflict: 'user_id');

      // Handle realtime channel
      if (status == 'online') {
        if (_presenceChannel == null || !_isInitialized) {
          await initializePresence();
        } else {
          try {
            await _presenceChannel!.track(
                {'user_id': userId, 'online_at': timestamp, 'status': status});
          } catch (e) {
            await initializePresence();
          }
        }
      }
    } catch (e) {
      if (status == 'online') {
        _isInitialized = false;
        await initializePresence();
      }
    }
  }

  Future<void> cleanupOldPresence() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existingPresence = await _supabase
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingPresence != null) {
        await _supabase.from('user_presence').delete().eq('user_id', userId);

        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e, stack) {
      _logger.error('Error cleaning up old presence', e, stack);
    }
  }

  Stream<Map<String, dynamic>> getUserPresence(String userId) {
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      try {
        final dbPresence = await _supabase
            .from('user_presence')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (dbPresence != null) {
          return {
            'user_id': dbPresence['user_id']?.toString(),
            'status': dbPresence['status']?.toString(),
            'last_seen': dbPresence['last_seen']?.toString(),
          };
        }

        final presences = _presenceChannel?.presenceState();
        if (presences != null) {
          for (final state in presences) {
            for (final presence in state.presences) {
              if (presence.payload['user_id'] == userId ||
                  presence.presenceRef == userId) {
                return {
                  'user_id': userId,
                  'status': presence.payload['status'] ?? 'online',
                  'online_at': presence.payload['online_at'],
                };
              }
            }
          }
        }

        return {
          'user_id': userId,
          'status': 'offline',
          'last_seen': null,
        };
      } catch (e) {
        return {
          'user_id': userId,
          'status': 'error',
          'last_seen': null,
        };
      }
    }).distinct((previous, next) =>
        previous['status'] == next['status'] &&
        previous['last_seen'] == next['last_seen']);
  }

  Stream<Map<String, dynamic>> getUserPresenceFromDB(String userId) {
    return _supabase
        .from('user_presence')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) {
            return {
              'user_id': userId,
              'status': 'offline',
              'last_seen': null,
            };
          }
          return data.first;
        });
  }

  Future<void> dispose() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_presence').upsert({
        'user_id': userId,
        'status': 'offline',
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      await _presenceChannel?.unsubscribe();
      _presenceChannel = null;
      _isInitialized = false;
    } catch (e, stack) {
      _logger.error('Error disposing presence service', e, stack);
    }
  }
}
