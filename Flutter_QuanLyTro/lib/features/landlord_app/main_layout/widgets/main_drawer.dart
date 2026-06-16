import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/response/area_model.dart';
import '../../../../data/models/response/user_model.dart';
import '../../onboarding/onboarding_screen.dart';
import '../../area_management/edit_area_screen.dart';
import '../../setting_page/settings_screen.dart';
import '../../setting_page/view_models/settings_viewmodel.dart';

class MainDrawer extends StatelessWidget {
  final UserModel? currentUser;
  final AreaModel? selectedArea;
  final Function(AreaModel area) onAreaCreated;
  final VoidCallback onAreaUpdated;

  const MainDrawer({
    super.key,
    required this.currentUser,
    required this.selectedArea,
    required this.onAreaCreated,
    required this.onAreaUpdated,
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
            onTap: () async {
              Navigator.pop(context);

              if (selectedArea == null) return;

              // Đổi từ OnboardingScreen sang EditAreaScreen mới tách
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditAreaScreen(
                    area: selectedArea!,
                  ),
                ),
              );

              if (result == true) {
                onAreaUpdated();
              }
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => SettingsViewModel(),
                    child: const SettingsScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}