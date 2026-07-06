import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/welcome/welcome_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/token_manager.dart';
import '../../../../data/repository/user_repository.dart';
import '../home_page/home_page_screen.dart';
import '../main_layout/main_layout_screen.dart';
import '../main_layout/view_models/main_layout_view_model.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserRepository _userProvider = UserRepository();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Chờ 1 khoảng ngắn để tránh việc màn hình bị nháy quá nhanh
    await Future.delayed(const Duration(seconds: 1));

    // Lấy accessToken từ Secure Storage
    final token = await TokenManager.getAccessToken();

    // ko có Token -> Chuyển sang trang chào mừng
    if (token == null) {
      _navigateToWelcome();
      return;
    }

    // Trường hợp CÓ Token -> Gọi API check xem còn hạn không
    try {
      await _userProvider.getCurrentUser();
      _navigateToHome();
    } catch (e) {
      await TokenManager.clearAuthData();
      _navigateToWelcome();
    }
  }

  void _navigateToWelcome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => MainLayoutViewModel()..fetchInitialData(),
            child: const MainLayoutScreen(),
          ),
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
            Icon(Icons.home_work_outlined, size: 80, color: AppColors.primary),
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