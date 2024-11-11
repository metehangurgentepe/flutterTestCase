import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/providers/snackbar_provider.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final Ref _ref;
  final _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._supabase, this._ref);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();

      if (Platform.isIOS) {
        await Future.delayed(const Duration(seconds: 5));
        await _waitForAPNSToken();
      }

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        if (message.notification != null) {
          _ref.read(snackbarProvider).showSnackBar(
            title: message.notification?.title ?? '',
            message: message.notification?.body ?? '',
          );
          print('Notification Title: ${message.notification?.title}');
          print('Notification Body: ${message.notification?.body}');
        }
      });

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        
        await _setupToken();
      } else {
        print('User declined permission');
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,  
      title,
      body,
      details,
    );
  }

  Future<void> _setupToken() async {
    try {
      if (Platform.isIOS) {
        await _waitForAPNSToken();
      }
      
      String? fcmToken = await _messaging.getToken();
      print('FCM Token: $fcmToken');
      
      if (fcmToken != null) {
        await _saveFCMToken(fcmToken);
      }

      _messaging.onTokenRefresh.listen(_saveFCMToken);
      
    } catch (e) {
      print('Error setting up token: $e');
    }
  }

  Future<void> _waitForAPNSToken() async {
    int attempts = 0;
    while (attempts < 5) {
      try {
        final apnsToken = await _messaging.getToken();
        if (apnsToken != null) {
          print('APNS Token: $apnsToken');
          return;
        }
      } catch (e) {
        print('Attempt $attempts: Waiting for APNS token...');
      }
      attempts++;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.id != null && user?.email != null) {
        await _supabase.from('profiles').upsert({
          'id': user!.id,
          'username': user.email!.split('@')[0],
          'email': user.email,
          'fcm_token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }, onConflict: 'id');
        print('Token saved to Supabase');
      }
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  Future<void> setupToken([String? topicId]) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _updateTokenInDatabase(token);
    }

    if (Platform.isIOS) {
      String? apnsToken;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries && apnsToken == null) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          retryCount++;
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (apnsToken != null && topicId != null) {
        await _messaging.subscribeToTopic(topicId);
      } else {
        print('Failed to get APNS token after $maxRetries attempts');
      }
    } else if (topicId != null) {
      await _messaging.subscribeToTopic(topicId);
    }
  }

  Future<void> _updateTokenInDatabase(String token) async {
    // Implement your token storage logic here
    // For example, update the current user's FCM token
  }

  void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await setupToken();
    });
  }
}