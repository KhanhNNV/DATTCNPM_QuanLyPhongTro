import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_quanlytro/core/constants/app_colors.dart';
import 'features/landlord_app/auth/splash_screen.dart';
import 'features/landlord_app/main_layout/view_models/main_layout_view_model.dart';
import 'features/landlord_app/notification/view_models/notification_view_model.dart';
import 'firebase_options.dart';

// --- KHỞI TẠO LOCAL NOTIFICATIONS ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Kênh này dùng để hiện biểu ngữ (pop-up) quan trọng.',
  importance: Importance.max,
);

// --- HÀM XỬ LÝ BACKGROUND FCM CỦA CHỦ TRỌ ---
@pragma('vm:entry-point')
Future<void> _landlordBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("📩 [Background FCM] Đã nhận thông báo: ${message.notification?.title}");
}

// Khai báo navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Cấu hình Kênh thông báo cho Android (Để bật Pop-up rớt xuống)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
  );

  // 3. Lắng nghe FCM khi app đóng hoặc chạy ngầm (Background / Terminated)
  FirebaseMessaging.onBackgroundMessage(_landlordBackgroundMessageHandler);

  // 4. Lắng nghe FCM khi app đang mở (Foreground) -> Ép vẽ Pop-up bằng Local Notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 [Foreground FCM] Đã nhận thông báo: ${message.notification?.title}");

    // ==========================================
    // SỬA Ở ĐÂY: Cập nhật số chuông + Tải lại danh sách
    // ==========================================
    final context = navigatorKey.currentContext;
    if (context != null) {
      final notificationVM = context.read<NotificationViewModel>();

      // 1. Cập nhật số lượng trên chuông
      notificationVM.fetchUnreadCount();

      // 2. Gọi API nạp thêm thông báo mới ngầm dưới nền
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

  // 5. Xử lý sự kiện khi người dùng bấm vào thông báo để mở app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("👆 [Opened FCM] Người dùng vừa bấm vào thông báo, data: ${message.data}");
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainLayoutViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Phòng Trọ',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}