import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // 1. Sửa getInstance() thành instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initFCM() async {
    // 1. Xin quyền (Đặc biệt quan trọng với iOS và Android 13+)
    NotificationSettings fcmSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (fcmSettings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Người dùng đã cấp quyền nhận thông báo.');
    }

    // 2. Cấu hình Local Notification cho Foreground
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);

    // 3. Sửa lỗi initialize: Dùng tham số có tên (named parameter)
    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        print(details.payload);
      },
    );

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Nhận được tin nhắn khi đang mở app: ${message.notification?.title}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Mở app từ thông báo: ${message.notification?.title}');
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel', // channelId
      'High Importance Notifications', // channelName
      channelDescription: 'Kênh hiển thị thông báo quan trọng.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // 4. Sửa lỗi show: Truyền đầy đủ tham số có tên (id, title, body, notificationDetails)
    await _localNotificationsPlugin.show(
      id: message.notification?.hashCode ?? 0, // Tránh lỗi null hashCode
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }
}