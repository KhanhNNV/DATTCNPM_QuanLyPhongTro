import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/token_manager.dart';
// Bạn nhớ kiểm tra lại đường dẫn import này cho khớp với cấu trúc thư mục nhé
import '../../../../data/repository/user_repository.dart';
import '../main_layout/tenant_main_layout_screen.dart';
import '../main_layout/view_models/tenant_main_layout_view_model.dart';
import 'tenant_login_screen.dart';

class TenantSplashScreen extends StatefulWidget {
  const TenantSplashScreen({super.key});

  @override
  State<TenantSplashScreen> createState() => _TenantSplashScreenState();
}

class _TenantSplashScreenState extends State<TenantSplashScreen> {
  final UserRepository _userProvider = UserRepository();

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
      // Gọi API để xác thực Token.
      await _userProvider.getCurrentUser();
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
      Provider.of<TenantMainLayoutViewModel>(context, listen: false).fetchInitialData();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TenantMainLayoutScreen(),
        ),
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