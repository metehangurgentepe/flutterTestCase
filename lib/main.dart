import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/providers/life_cycle_provider.dart';
import 'package:test_case/core/routes/app_router.dart';
import 'package:test_case/core/utils/helpers/notification_service.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';
import 'package:test_case/features/auth/view/auth_wrapper.dart';
import 'package:test_case/features/chat/view/chat_view.dart';
import 'core/init/supabase_init.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = Supabase.instance.client;
  return NotificationService(supabase);
});

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final supabase = Supabase.instance.client;
  return PresenceService(supabase);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await SupabaseInit.init();

  await requestNotificationPermissions();
  
  // Get Supabase instance
  final supabase = Supabase.instance.client;
  
  // Get current user if logged in
  final currentUser = supabase.auth.currentUser;

  runApp(
    ProviderScope(
      overrides: [
        
        if (currentUser != null)
          notificationServiceProvider.overrideWith((ref) {
            final service = NotificationService(supabase);
            service.initialize(currentUser.id);
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
    ref.watch(lifecycleHandlerProvider);
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Pushed route: ${route.settings.name}');
  }
}


Future<void> requestNotificationPermissions() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  // Android için
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  // iOS için (eğer iOS desteği de istiyorsanız)
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
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      // Bildirime tıklandığında ne yapılacağı
    },
  );
}