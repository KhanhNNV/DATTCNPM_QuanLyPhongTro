import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/main_layout/view_models/main_layout_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../home_page/home_page_screen.dart';
import 'widgets/main_app_bar.dart';
import 'widgets/main_drawer.dart';
import 'widgets/main_bottom_bar.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  // Khởi tạo ViewModel
  final MainLayoutViewModel _viewModel = MainLayoutViewModel();

  final List<Widget> _screens = [
    const HomePageScreen(),
    const Center(child: Text('Màn hình Khách thuê (Đang xây dựng)')),
    const Center(child: Text('Màn hình Hóa đơn (Đang xây dựng)')),
    const Center(child: Text('Màn hình Cài đặt (Đang xây dựng)')),
  ];

  @override
  void initState() {
    super.initState();
    _viewModel.fetchInitialData();
  }

  // Hàm hiển thị danh sách chọn khu trọ
  void _showAreaSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Chọn khu trọ quản lý',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_viewModel.areas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Bạn chưa tạo khu trọ nào.'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _viewModel.areas.length,
                          itemBuilder: (context, index) {
                            final area = _viewModel.areas[index];
                            final isSelected = area.id == _viewModel.selectedArea?.id;

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
                                _viewModel.changeArea(area);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              }
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bao bọc toàn bộ màn hình bằng ListenableBuilder để lắng nghe ViewModel
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {

        // Logic hiển thị Tên trên Header
        String displayName = "Đang tải...";
        if (!_viewModel.isLoading) {
          displayName = _viewModel.selectedArea?.name ?? "Chưa có khu trọ";
        }
        if (_viewModel.errorMessage != null) {
          displayName = "Lỗi tải dữ liệu";
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],

          appBar: MainAppBar(
            currentAreaName: displayName,
            onTitleTap: _viewModel.isLoading || _viewModel.areas.isEmpty ? () {} : _showAreaSelection,
          ),

          endDrawer: MainDrawer(
            currentUser: _viewModel.currentUser,
            onAreaCreated: (newArea) {
              _viewModel.addAndSelectArea(newArea);
            },
          ),

          body: _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _viewModel.errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text('Lỗi: ${_viewModel.errorMessage}', style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _viewModel.fetchInitialData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
              : IndexedStack(
            index: _viewModel.currentIndex,
            children: _screens,
          ),

          bottomNavigationBar: MainBottomBar(
            currentIndex: _viewModel.currentIndex,
            onTabSelected: _viewModel.changeTab,
          ),
        );
      },
    );
  }
}