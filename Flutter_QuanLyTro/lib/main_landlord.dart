import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_quanlytro/core/constants/app_colors.dart';
import 'features/landlord_app/auth/splash_screen.dart';
import 'features/landlord_app/main_layout/view_models/main_layout_view_model.dart';
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

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Đã sửa lỗi "Too many positional arguments" bằng cách gọi tên các tham số (id, title, body...)
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

    // TODO: (Tương lai) Đọc message.data để lấy ID hợp đồng/phòng và dùng navigatorKey
    // để chuyển hướng thẳng tới màn hình chi tiết tương ứng.
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainLayoutViewModel()),
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