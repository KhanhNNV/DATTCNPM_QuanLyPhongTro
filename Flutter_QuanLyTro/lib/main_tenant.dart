import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quanlytro/core/constants/app_colors.dart';
// Import các file của Khách thuê (thay đổi đường dẫn theo thực tế của bạn)
// import 'features/tenant_app/auth/splash_screen_tenant.dart';
// import 'features/tenant_app/main_layout/view_models/tenant_layout_view_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
      const TenantApp()
  );
}

class TenantApp extends StatelessWidget {
  const TenantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phòng trọ', // Tên app cho Khách thuê
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Có thể đổi màu chủ đạo khác để dễ phân biệt 2 app
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('App Khách Thuê 2WSS'))), // Tạm thời để test
    );
  }
}