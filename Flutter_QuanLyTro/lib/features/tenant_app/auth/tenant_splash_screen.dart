import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/token_manager.dart';
import '../main_layout/tenant_main_layout_screen.dart';
import 'tenant_login_screen.dart';

class TenantSplashScreen extends StatefulWidget {
  const TenantSplashScreen({super.key});

  @override
  State<TenantSplashScreen> createState() => _TenantSplashScreenState();
}

class _TenantSplashScreenState extends State<TenantSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 1));

    final token = await TokenManager.getAccessToken();

    // Không có Token -> Chuyển thẳng sang trang Đăng nhập
    if (token == null) {
      _navigateToLogin();
      return;
    }

    try {
      _navigateToHome();
    } catch (e) {
      await TokenManager.clearAuthData();
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TenantLoginScreen()),
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TenantMainLayoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon phòng thay cho tòa nhà để hợp với Khách thuê
            Icon(Icons.meeting_room_outlined, size: 80, color: AppColors.primary),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}