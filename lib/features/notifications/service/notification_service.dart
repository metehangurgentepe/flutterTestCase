import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/routes/app_router.dart';
import 'package:test_case/firebase_options.dart';
import 'package:test_case/core/services/logging_service.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final Ref _ref;
  final _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final LoggingService _loggingService;

  NotificationService(this._supabase, this._ref)
      : _loggingService = LoggingService(_supabase);

  @pragma('vm:entry-point')
  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
        
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

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      details,
      payload: message.data['roomId'],
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _initializeLocalNotifications();

      await _requestNotificationPermissions();

      _setupMessageHandlers();

      _isInitialized = true;
    } catch (e) {
      _loggingService.logError('Error initializing notifications', e);
    }
  }

  Future<void> _requestNotificationPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _setupToken();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? roomId = response.payload;
        if (roomId != null && roomId.isNotEmpty) {
          _navigateToChatRoom(roomId);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'default_channel',
            'Default Channel',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );
  }

  Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final roomId = initialMessage.data['roomId'];
        if (roomId != null) {
          await Future.delayed(Duration(milliseconds: 500));
          _navigateToChatRoom(roomId);
        }
      }
    } catch (e) {
      _loggingService.logError('Error checking initial message', e);
    }
  }

  void _navigateToChatRoom(String roomId) {
    try {
      AppRouter.router.push('/chat/$roomId', extra: 'Chat Room');
    } catch (e) {
      _loggingService.logError('Navigation error', e);
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String roomId,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Channel',
        importance: Importance.high,
        priority: Priority.high,
        fullScreenIntent: true,
        channelShowBadge: true,
        enableLights: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'open_chat',
            'Aç',
            showsUserInterface: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: roomId,
      );
    } catch (e) {
      _loggingService.logError('Error showing local notification', e);
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification?.title ?? '',
          body: message.notification?.body ?? '',
          roomId: message.data['roomId'] ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final roomId = message.data['roomId'];
      if (roomId != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          _navigateToChatRoom(roomId);
        });
      }
    });

    _checkInitialMessage();
  }

  Future<void> _setupLocalNotificationTapHandler() async {
    _localNotifications.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? roomId = response.payload;
        if (roomId != null) {
          _navigateToChatRoom(roomId);
        }
      },
    );
  }

  Future<void> _setupToken() async {
    try {
      if (Platform.isIOS) {
        await _waitForAPNSToken();
      }

      String? fcmToken = await _messaging.getToken();

      if (fcmToken != null) {
        await _saveFCMToken(fcmToken);
      }

      _messaging.onTokenRefresh.listen(_saveFCMToken);
    } catch (e) {
      _loggingService.logError('Error setting up token', e);
    }
  }

  Future<void> _waitForAPNSToken() async {
    int attempts = 0;
    while (attempts < 5) {
      try {
        final apnsToken = await _messaging.getToken();
        if (apnsToken != null) {
          return;
        }
      } catch (e) {
        _loggingService.logError('Attempt $attempts: Waiting for APNS token', e);
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
      }
    } catch (e) {
      _loggingService.logError('Error saving token', e);
    }
  }

  Future<void> setupToken([String? topicId]) async {
    try {
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
        }
      } else if (topicId != null) {
        await _messaging.subscribeToTopic(topicId);
      }
    } catch (e) {
      _loggingService.logError('Error setting up token with topic', e);
    }
  }

  Future<void> _updateTokenInDatabase(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.id != null) {
        await _supabase.from('profiles').upsert({
          'id': user!.id,
          'fcm_token': token,
        }, onConflict: 'id');
      }
    } catch (e) {
      _loggingService.logError('Error updating token in database', e);
    }
  }

  void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await setupToken();
      } catch (e) {
        _loggingService.logError('Error handling token refresh', e);
      }
    });
  }
}
