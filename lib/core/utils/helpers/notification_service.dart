import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final _notificationsPlugin = FlutterLocalNotificationsPlugin();
  StreamSubscription? _subscription;
  RealtimeChannel? _channel;

  NotificationService(this._supabase) {
    _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        
      },
    );
  }

  void initialize(String userId) {
    dispose();

    _channel = _supabase.channel('public:messages');

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        await _handleNewMessage(payload, userId);
      },
    );

    _channel!.subscribe((status, error) {
      if (error != null) {
        print('Realtime subscription error: $error');
      } else {
        print('Realtime subscription status: $status');
      }
    });
  }

  Future<void> _handleNewMessage(PostgresChangePayload payload, String currentUserId) async {
    try {
      final message = payload.newRecord;
      
      if (message['user_id'] == currentUserId) return;

      final roomId = message['room_id'];
      final room = await _supabase
          .from('chat_rooms')
          .select('name, is_group')
          .eq('id', roomId)
          .single();

      final sender = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', message['user_id'])
          .single();

      final senderName = sender['username'] as String? ?? 'Unknown';
      final content = message['content'] as String? ?? '';
      final isGroup = room['is_group'] as bool? ?? false;
      final roomName = room['name'] as String? ?? 'Chat';

      await _showLocalNotification(
        title: isGroup ? roomName : senderName,
        body: content,
        payload: {
          'room_id': roomId,
          'message_id': message['id'],
          'is_group': isGroup,
        }.toString(),
      );
    } catch (e) {
      print('Error handling new message notification: $e');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        color: Color.fromARGB(255, 33, 150, 243),
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  Future<void> requestPermissions() async {
    final platform = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (platform != null) {
      await platform.requestNotificationsPermission();
    }

    final ios = _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (ios != null) {
      await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> clearNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.unsubscribe();
    _channel = null;
  }
}