import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/response/area_model.dart';
import '../../../../data/models/response/user_model.dart';
import '../../area_management/view_models/edit_area_view_model.dart';
import '../../onboarding/onboarding_screen.dart';
import '../../area_management/edit_area_screen.dart';
import '../../onboarding/view_models/onboarding_view_model.dart';
import '../../setting_page/settings_screen.dart';
import '../../setting_page/view_models/settings_viewmodel.dart';
import '../../welcome/welcome_screen.dart';
import '../view_models/main_layout_view_model.dart';

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
              final isUpdated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => EditAreaViewModel()..initData(selectedArea!),
                    child: EditAreaScreen(area: selectedArea!),
                  ),
                ),
              );

              if (isUpdated == true) {
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
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => OnboardingViewModel(),
                    child: const OnboardingScreen(isAddingNewArea: true),
                  ),
                ),
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
                    create: (_) => SettingsViewModel()..fetchCurrentUser(),
                    child: const SettingsScreen(),
                  ),
                ),
              );
            },
          ),

          const Spacer(),
          const Divider(),


          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {

              final navigator = Navigator.of(context);
              final mainViewModel = Provider.of<MainLayoutViewModel>(context, listen: false);


              navigator.pop();


              await mainViewModel.logout();

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
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