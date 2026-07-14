import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.apartment_rounded,
                size: 120,
                color: AppColors.primary,
              ),
              const SizedBox(height: 40),


              const Text(
                'Chào mừng đến với\nQuản Lý Phòng Trọ\nThông Minh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),


              const Text(
                'Giải pháp toàn diện để quản lý phòng trọ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),


              const Text(
                'Chuyên nghiệp - Tự động hóa\nTiết kiệm - Linh hoạt',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.primary,
                  height: 1.5,
                  fontWeight: FontWeight.bold
                ),
              ),
              const Spacer(),


              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bắt đầu quản lý', style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600
                      ),),
                      SizedBox(width: 8,),
                      Icon(Icons.arrow_forward)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}