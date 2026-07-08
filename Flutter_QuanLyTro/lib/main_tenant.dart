import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quanlytro/core/constants/app_colors.dart';
import 'features/tenant_app/auth/tenant_splash_screen.dart';
import 'features/tenant_app/main_layout/view_models/tenant_main_layout_view_model.dart'; // Import ViewModel vào đây

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Đặt ở đây để dùng chung xuyên suốt vòng đời của App Tenant
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