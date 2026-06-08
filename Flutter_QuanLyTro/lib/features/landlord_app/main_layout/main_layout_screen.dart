import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quanlytro/features/landlord_app/main_layout/view_models/main_layout_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../home_page/home_page_screen.dart';
import '../home_page/home_screen.dart';
import 'widgets/main_app_bar.dart';
import 'widgets/main_drawer.dart';
import 'widgets/main_bottom_bar.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {

  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu lần đầu sau khi UI đã render xong khung cơ bản
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MainLayoutViewModel>().fetchInitialData();
    });
  }

  // Hàm hiển thị danh sách chọn khu trọ
  void _showAreaSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        // Dùng context.watch để lắng nghe thay đổi ngay trong BottomSheet
        final viewModel = bottomSheetContext.watch<MainLayoutViewModel>();

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Chọn khu trọ quản lý',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    itemCount: viewModel.areas.length,
                    itemBuilder: (context, index) {
                      final area = viewModel.areas[index];
                      final isSelected = area.id == viewModel.selectedArea?.id;

                      return ListTile(
                        leading: Icon(
                          Icons.home_work,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        title: Text(
                          area.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                        subtitle: Text(area.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary)
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // context.watch sẽ tự động build lại màn hình này mỗi khi ViewModel gọi notifyListeners()
    final viewModel = context.watch<MainLayoutViewModel>();

    // Logic hiển thị Tên trên Header
    String displayName = "Đang tải...";
    if (!viewModel.isLoading) {
      displayName = viewModel.selectedArea?.name ?? "Chưa có khu trọ";
    }
    if (viewModel.errorMessage != null) {
      displayName = "Lỗi tải dữ liệu";
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: MainAppBar(
        currentAreaName: displayName,
        onTitleTap: viewModel.isLoading || viewModel.areas.isEmpty ? () {} : _showAreaSelection,
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : viewModel.errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Lỗi: ${viewModel.errorMessage}', style: const TextStyle(color: Colors.redAccent)),
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
          const Center(child: Text('Màn hình Khách thuê')),
          const Center(child: Text('Màn hình Hóa đơn')),
          const Center(child: Text('Màn hình Cài đặt')),
        ],
      ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: viewModel.currentIndex,
        onTabSelected: viewModel.changeTab,
      ),
    );
  }
}