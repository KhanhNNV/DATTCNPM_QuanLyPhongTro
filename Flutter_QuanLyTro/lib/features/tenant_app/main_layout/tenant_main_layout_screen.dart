import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';

import '../../landlord_app/notification/notification_screen.dart';
import '../../landlord_app/notification/view_models/notification_view_model.dart';
import '../home_page/tenant_home_screen.dart';
import 'view_models/tenant_main_layout_view_model.dart';
import 'widgets/tenant_main_app_bar.dart';
import 'widgets/tenant_main_bottom_bar.dart';
import 'widgets/tenant_main_drawer.dart';

class TenantMainLayoutScreen extends StatelessWidget {
  const TenantMainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantMainLayoutViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: TenantMainAppBar(
        roomNumber: viewModel.displayRoomNumber,
        areaName: viewModel.displayAreaName,
      ),
      endDrawer: TenantMainDrawer(
        tenantName: viewModel.displayTenantName,
        tenantPhone: viewModel.displayTenantPhone,
      ),
      body: viewModel.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : viewModel.errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Lỗi: ${viewModel.errorMessage}',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.fetchInitialData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : IndexedStack(
        index: viewModel.currentIndex,
        children: [
          const TenantHomeScreen(),
          ChangeNotifierProvider(
            create: (_) => NotificationViewModel()..fetchNotifications(),
            child: const NotificationScreen(),
          ),
        ],
      ),
      bottomNavigationBar: TenantMainBottomBar(
        currentIndex: viewModel.currentIndex,
        onTabSelected: viewModel.changeTab,
      ),
    );
  }
}