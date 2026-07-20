import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/landlord_app/notification/view_models/notification_view_model.dart';
import '../../firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Kênh này dùng để hiện biểu ngữ (pop-up) quan trọng.',
  importance: Importance.max,
);

// Bắt buộc phải là top-level function để chạy ngầm
@pragma('vm:entry-point')
Future<void> _landlordBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("[Background FCM] Đã nhận thông báo: ${message.notification?.title}");
}

class NotificationService {
  // Nhận navigatorKey từ main.dart để có thể gọi context cập nhật UI
  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // Tạo Channel Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Khởi tạo Local Notifications
    const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(settings: initSettings);

    // Background Message
    FirebaseMessaging.onBackgroundMessage(_landlordBackgroundMessageHandler);

    // Foreground Message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("[Foreground FCM] Đã nhận thông báo: ${message.notification?.title}");

      // Cập nhật View Model
      final context = navigatorKey.currentContext;
      if (context != null) {
        try {
          final notificationVM = context.read<NotificationViewModel>();
          notificationVM.fetchUnreadCount();
          notificationVM.fetchNotifications(isRefresh: true);
        } catch (e) {
          debugPrint("Lỗi cập nhật View Model: $e");
        }
      }

      // Hiện Pop-up
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

    // Mở App từ thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("[Opened FCM] Người dùng bấm vào thông báo, data: ${message.data}");
    });
  }
}