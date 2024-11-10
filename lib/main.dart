import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/providers/life_cycle_provider.dart';
import 'package:test_case/core/providers/snackbar_provider.dart';
import 'package:test_case/core/routes/app_router.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';
import 'package:test_case/features/notifications/service/notification_service.dart';
import 'core/init/supabase_init.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = Supabase.instance.client;
  return NotificationService(supabase, ref);
});

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final supabase = Supabase.instance.client;
  return PresenceService(supabase);
});

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message data: ${message.data}');
  print('Background message notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");
  await SupabaseInit.init();
  await requestNotificationPermissions();

  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Notification Title: ${message.notification?.title}');
    print('Notification Body: ${message.notification?.body}');

    // Snackbar'ı göster
    container.read(snackbarProvider).showSnackBar(
          title: message.notification?.title ?? 'New Message',
          message: message.notification?.body ?? '',
        );
  });

  runApp(
    ProviderScope(
      parent: container,
      overrides: [
        if (currentUser != null)
          notificationServiceProvider.overrideWith((ref) {
            final service = NotificationService(
              supabase,
              ref,
            );
            service.initialize();
            return service;
          }),
        presenceServiceProvider.overrideWith((ref) {
          return PresenceService(supabase);
        }),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(snackbarProvider);
    ref.watch(lifecycleHandlerProvider);

    return MaterialApp.router(
      routerConfig: AppRouter.router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}

Future<void> requestNotificationPermissions() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {},
  );
}
