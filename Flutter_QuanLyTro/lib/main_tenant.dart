import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_quanlytro/core/constants/app_colors.dart';
import 'features/tenant_app/auth/tenant_splash_screen.dart';
import 'features/tenant_app/main_layout/view_models/tenant_main_layout_view_model.dart';
// THÊM IMPORT NÀY
import 'features/landlord_app/notification/view_models/notification_view_model.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Kênh này dùng để hiện biểu ngữ (pop-up) quan trọng.',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> _tenantBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("🔵 [Background FCM] Khách thuê nhận thông báo: ${message.notification?.title}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
  );

  FirebaseMessaging.onBackgroundMessage(_tenantBackgroundMessageHandler);

  // 4. Lắng nghe FCM khi app đang mở (Foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("🔵 [Foreground FCM] Khách thuê nhận thông báo: ${message.notification?.title}");

    // ==========================================
    // 🚀 SỬA TẠI ĐÂY: Tự động cập nhật số chuông & danh sách thông báo
    // ==========================================
    final context = navigatorKey.currentContext;
    if (context != null) {
      final notificationVM = context.read<NotificationViewModel>();
      // 1. Cập nhật số Badge hiển thị trên chuông
      notificationVM.fetchUnreadCount();
      // 2. Gọi tải lại danh sách ngầm (không chớp màn hình)
      notificationVM.fetchNotifications(isRefresh: true);
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("👆 [Opened FCM] Khách thuê vừa bấm vào thông báo, data: ${message.data}");
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TenantMainLayoutViewModel()),
        // KHỞI TẠO GLOBAL NOTIFICATION VIEWMODEL TẠI ĐÂY
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: const TenantApp(),
    ),
  );
}

class TenantApp extends StatelessWidget {
  const TenantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phòng Của Tôi',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const TenantSplashScreen(),
    );
  }
}