import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/welcome/welcome_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/token_manager.dart';
import '../../../../data/repository/user_repository.dart';
import '../main_layout/main_layout_screen.dart';
import '../main_layout/view_models/main_layout_view_model.dart';
import '../notification/view_models/notification_view_model.dart';

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

    await Future.delayed(const Duration(seconds: 1));

    final token = await TokenManager.getAccessToken();

    if (token == null) {
      _navigateToWelcome();
      return;
    }

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
      context.read<MainLayoutViewModel>().fetchInitialData();

      context.read<NotificationViewModel>().fetchUnreadCount();

      context.read<NotificationViewModel>().fetchNotifications(isRefresh: true);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainLayoutScreen(),
        ),
            (route) => false,
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