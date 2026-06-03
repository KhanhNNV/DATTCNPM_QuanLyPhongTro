import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MainDrawer extends StatelessWidget {
  final String currentAreaName;

  const MainDrawer({
    super.key,
    required this.currentAreaName,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              currentAreaName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('Quản lý khu trọ'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.home_work, color: AppColors.primary, size: 32),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Chỉnh sửa thông tin nhà trọ'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Điều hướng sang màn hình chỉnh sửa
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_business_outlined),
            title: const Text('Thêm mới nhà trọ'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Điều hướng sang OnboardingScreen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Cài đặt'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}