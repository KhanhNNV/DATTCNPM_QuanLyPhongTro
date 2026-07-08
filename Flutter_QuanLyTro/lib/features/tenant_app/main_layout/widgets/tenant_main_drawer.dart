import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Thêm import Provider
import '../../../../core/constants/app_colors.dart';
import '../../auth/tenant_login_screen.dart';
import '../view_models/tenant_main_layout_view_model.dart';

class TenantMainDrawer extends StatelessWidget {
  final String tenantName;
  final String tenantPhone;

  const TenantMainDrawer({
    super.key,
    required this.tenantName,
    required this.tenantPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              tenantName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(tenantPhone),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primary, size: 32),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Cài đặt'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Điều hướng sang màn Settings của Khách thuê
            },
          ),

          const Spacer(),
          const Divider(),

          // Nút Đăng xuất
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              // Lưu lại Navigator và ViewModel trước khi context của Drawer bị hủy
              final navigator = Navigator.of(context);
              final viewModel = Provider.of<TenantMainLayoutViewModel>(context, listen: false);

              // Đóng Drawer ngay lập tức để phản hồi UI mượt mà
              navigator.pop();

              // Chờ ViewModel xử lý logic gọi API và dọn dẹp RAM + Token
              await viewModel.logout();

              // Dùng navigator đã lưu để chuyển ra màn Đăng nhập và xóa sạch lịch sử
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const TenantLoginScreen()),
                    (route) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}