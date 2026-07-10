import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_quanlytro/core/constants/app_colors.dart';
import 'features/tenant_app/auth/tenant_splash_screen.dart';
import 'features/tenant_app/main_layout/view_models/tenant_main_layout_view_model.dart';
import 'firebase_options.dart'; // Đã mở comment để dùng chung cấu hình Firebase

// --- HÀM XỬ LÝ BACKGROUND FCM CỦA KHÁCH THUÊ ---
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

  // 1. Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Lắng nghe FCM khi app đóng hoặc chạy ngầm (Background / Terminated)
  FirebaseMessaging.onBackgroundMessage(_tenantBackgroundMessageHandler);

  // 3. Lắng nghe FCM khi app đang mở (Foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("🔵 [Foreground FCM] Khách thuê nhận thông báo: ${message.notification?.title}");

    // TODO: (Tương lai) Hiển thị popup thông báo trong app (in-app notification)
    // hoặc trigger load lại danh sách thông báo/hóa đơn mới nhất.
  });

  // 4. Xử lý sự kiện khi người dùng bấm vào thông báo để mở app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("👆 [Opened FCM] Khách thuê vừa bấm vào thông báo, data: ${message.data}");

    // TODO: (Tương lai) Dựa vào message.data để điều hướng đến màn hình thanh toán,
    // hợp đồng hoặc chi tiết thông báo tương ứng.
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TenantMainLayoutViewModel()),
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
      navigatorKey: navigatorKey, // Chìa khóa để điều hướng không cần context sau này
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const TenantSplashScreen(),
    );
  }
}