import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_quanlytro/core/constants/app_colors.dart';
import 'features/landlord_app/auth/splash_screen.dart';
import 'features/landlord_app/main_layout/view_models/main_layout_view_model.dart';
import 'firebase_options.dart';

// --- HÀM XỬ LÝ BACKGROUND FCM CỦA CHỦ TRỌ ---
@pragma('vm:entry-point')
Future<void> _landlordBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("📩 [Background FCM] Đã nhận thông báo: ${message.notification?.title}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Lắng nghe FCM khi app đóng hoặc chạy ngầm (Background / Terminated)
  FirebaseMessaging.onBackgroundMessage(_landlordBackgroundMessageHandler);

  // 3. Lắng nghe FCM khi app đang mở (Foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 [Foreground FCM] Đã nhận thông báo: ${message.notification?.title}");

    // TODO: (Tương lai) Thêm logic hiển thị popup thông báo trong app (in-app notification)
    // hoặc dùng thư viện flutter_local_notifications để đẩy thông báo lên thanh trạng thái.
  });

  // 4. Xử lý sự kiện khi người dùng bấm vào thông báo để mở app
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