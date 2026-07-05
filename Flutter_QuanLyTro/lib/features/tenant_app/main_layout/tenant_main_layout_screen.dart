import 'package:flutter/material.dart';
import '../../../core/utils/token_manager.dart';
import '../auth/tenant_login_screen.dart';

class TenantMainLayoutScreen extends StatelessWidget {
  const TenantMainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng Của Tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              // Xóa token khi đăng xuất
              await TokenManager.clearAuthData();

              if (context.mounted) {
                // Đẩy người dùng về lại trang Đăng nhập và xóa lịch sử trang
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const TenantLoginScreen()),
                      (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text(
              'Đăng nhập thành công! \nChào mừng bạn đến với App Khách Thuê.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}