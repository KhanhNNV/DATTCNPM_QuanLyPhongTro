import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/onboarding/onboarding_screen.dart';
import 'package:flutter_quanlytro/features/landlord_app/onboarding/view_models/onboarding_view_model.dart';
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';

class SetupIntroScreen extends StatelessWidget {
  const SetupIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.maps_home_work_outlined,
                    size: 100,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),

                const Text(
                  'Chào mừng Chủ Trọ!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Bây giờ bạn là một chủ trọ. Hãy khởi tạo khu trọ và các dịch vụ cho các phòng trọ của bạn để bắt đầu quản lý nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
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
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => OnboardingViewModel(),
                            child: const OnboardingScreen(isAddingNewArea: false),
                          ),
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
                    child: const Text(
                      'Bắt đầu khởi tạo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}