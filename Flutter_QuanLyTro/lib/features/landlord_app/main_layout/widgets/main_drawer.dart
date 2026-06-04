import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/area_model.dart';
import '../../../../data/models/user_model.dart';
import '../../onboarding/onboarding_screen.dart';

class MainDrawer extends StatelessWidget {
  final UserModel? currentUser;
  final Function(AreaModel area) onAreaCreated;

  const MainDrawer({
    super.key,
    required this.currentUser,
    required this.onAreaCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              currentUser?.fullName ?? 'Đang tải...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(currentUser?.phone ?? '...'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primary, size: 32),
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
            onTap: () async {
              Navigator.pop(context);

              final AreaModel? newArea = await Navigator.push<AreaModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(isAddingNewArea: true),
                  )
              );

              if (newArea != null) {
                onAreaCreated(newArea);
              }
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