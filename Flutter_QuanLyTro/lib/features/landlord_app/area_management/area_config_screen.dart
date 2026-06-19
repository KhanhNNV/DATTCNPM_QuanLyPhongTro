import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_app_bar.dart';
import 'view_models/area_config_view_model.dart';
import 'widgets/services_tab_widget.dart'; // Import tab dịch vụ
import 'widgets/rooms_tab_widget.dart';

class AreaConfigScreen extends StatelessWidget {
  final String areaId;

  const AreaConfigScreen({super.key, required this.areaId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: CustomAppBar(
          title: 'Tinh chỉnh Khu trọ',
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.bolt), text: 'Dịch vụ'),
              Tab(icon: Icon(Icons.door_front_door), text: 'Phòng trọ'),
            ],
          ),
        ),
        body: Consumer<AreaConfigViewModel>(
          builder: (context, vm, _) {
            // Hiển thị loading khi đang tải dữ liệu lần đầu
            if (vm.isLoading && vm.services.isEmpty && vm.rooms.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Xử lý hiển thị lỗi Fetch ban đầu nếu có
            if (vm.errorMessage != null && vm.services.isEmpty) {
              return Center(
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return TabBarView(
              children: [
                ServicesTabWidget(areaId: areaId, vm: vm),
                RoomsTabWidget(areaId: areaId, vm: vm),
              ],
            );
          },
        ),
      ),
    );
  }
}