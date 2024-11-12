import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/providers/snackbar_provider.dart';

final notificationInitProvider = Provider<void>((ref) {
  _initializeNotifications(ref);
  return;
});

Future<void> _initializeNotifications(Ref ref) async {
  // Request permissions
  await _requestNotificationPermissions();
  
  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Setup foreground message handler
  _setupForegroundMessageHandler(ref);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  final notification = message.notification;
  final data = message.data;
  
  if (notification != null) {
    await _showLocalNotification(
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: data['roomId'],
    );
  }
}

void _setupForegroundMessageHandler(Ref ref) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    ref.read(snackbarProvider).showSnackBar(
          title: message.notification?.title ?? 'New Message',
          message: message.notification?.body ?? '',
        );
  });
}

Future<void> _requestNotificationPermissions() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  final iosSettings = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  final initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _handleNotificationResponse,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

void _handleNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload != null && payload.isNotEmpty) {
    // Handle navigation or other actions
  }
}

Future<void> _showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Default Channel',
    importance: Importance.high,
    priority: Priority.high,
  );

  const iosDetails = DarwinNotificationDetails();

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}