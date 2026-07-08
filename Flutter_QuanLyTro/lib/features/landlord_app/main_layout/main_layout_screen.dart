import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quanlytro/features/landlord_app/main_layout/view_models/main_layout_view_model.dart';

import '../../../core/constants/app_colors.dart';
import '../home_page/home_page_screen.dart';
import '../home_page/home_screen.dart';
import 'widgets/main_app_bar.dart';
import 'widgets/main_bottom_bar.dart';
import 'widgets/main_drawer.dart';

class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  void _showAreaSelection(BuildContext context) {
    // Lấy ViewModel từ context của màn hình chính TRƯỚC khi mở BottomSheet
    final parentViewModel = context.read<MainLayoutViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        // Sử dụng .value để truyền ViewModel hiện tại vào nhánh Widget Tree mới của BottomSheet
        return ChangeNotifierProvider<MainLayoutViewModel>.value(
          value: parentViewModel,
          child: Consumer<MainLayoutViewModel>(
            builder: (context, viewModel, child) {
              return SafeArea(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
                        child: Text(
                          'Chọn khu trọ quản lý',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (viewModel.areas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Bạn chưa tạo khu trọ nào.'),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: viewModel.areas.length,
                            itemBuilder: (context, index) {
                              final area = viewModel.areas[index];
                              final isSelected = area.id == viewModel.selectedArea?.id;

                              return ListTile(
                                leading: Icon(
                                  Icons.home_work,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                                title: Text(
                                  area.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  area.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                                    : null,
                                onTap: () {
                                  viewModel.changeArea(area);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MainLayoutViewModel>();

    String displayName = "Đang tải...";

    if (!viewModel.isLoading) {
      displayName =
          viewModel.selectedArea?.name ?? "Chưa có khu trọ";
    }

    if (viewModel.errorMessage != null) {
      displayName = "Lỗi tải dữ liệu";
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: MainAppBar(
        currentAreaName: displayName,
        onTitleTap: viewModel.isLoading || viewModel.areas.isEmpty
            ? () {}
            : () => _showAreaSelection(context),
      ),
      endDrawer: MainDrawer(
        currentUser: viewModel.currentUser,
        selectedArea: viewModel.selectedArea,
        onAreaCreated: (newArea) {
          viewModel.addAndSelectArea(newArea);
        },
        onAreaUpdated: () async {
          await viewModel.fetchInitialData();
        },
      ),
      body: viewModel.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : viewModel.errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi: ${viewModel.errorMessage}',
              style: const TextStyle(
                color: Colors.redAccent,
              ),
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
          HomePageScreen(
            selectedAreaId: viewModel.selectedAreaId,
          ),
          const HomeScreen(),
          const Center(
            child: Text('Màn hình Khách thuê'),
          ),
          const Center(
            child: Text('Màn hình Hóa đơn'),
          ),
          const Center(
            child: Text('Màn hình Cài đặt'),
          ),
        ],
      ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: viewModel.currentIndex,
        onTabSelected: viewModel.changeTab,
      ),
    );
  }
}