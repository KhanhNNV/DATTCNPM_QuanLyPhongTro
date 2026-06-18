import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import 'view_models/area_config_view_model.dart';

class AreaConfigScreen extends StatelessWidget {
  final String areaId;
  const AreaConfigScreen({super.key, required this.areaId});

  // --- CÁC HÀM TIỆN ÍCH UI ---
  String formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = double.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,###', 'vi_VN').format(number).replaceAll(',', '.');
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'AVAILABLE': return 'Trống';
      case 'DEPOSITED': return 'Đã cọc';
      case 'RENTED': return 'Đã thuê';
      case 'MAINTENANCE': return 'Bảo trì';
      default: return status ?? 'Không rõ';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'AVAILABLE': return Colors.green;
      case 'DEPOSITED': return Colors.redAccent;
      case 'RENTED': return Colors.redAccent;
      case 'MAINTENANCE': return Colors.orange;
      default: return Colors.grey;
    }
  }

  // --- GIAO DIỆN CHÍNH ---
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
            if (vm.isLoading && vm.services.isEmpty && vm.rooms.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Xử lý hiển thị lỗi Fetch ban đầu nếu có
            if (vm.errorMessage != null && vm.services.isEmpty) {
              return Center(
                child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
              );
            }

            return TabBarView(
              children: [
                _buildServicesTab(context, vm),
                _buildRoomsTab(context, vm),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================== QUẢN LÝ DỊCH VỤ ====================
  Widget _buildServicesTab(BuildContext context, AreaConfigViewModel vm) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.services.length,
      itemBuilder: (context, index) {
        final service = vm.services[index];
        final serviceIdStr = service['id'].toString();
        final priceController = vm.servicePriceControllers[serviceIdStr];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Cách tính: ${service['calcType']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Đơn giá (đ)', suffixText: 'đ'),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () async {
                      // Bỏ định dạng dấu phẩy/chấm nếu người dùng có nhập nhầm
                      final rawPrice = priceController?.text.replaceAll('.', '').replaceAll(',', '') ?? '0';
                      final success = await vm.saveService(
                        areaId,
                        service['id'],
                        {
                          "name": service['name'],
                          "calcType": service['calcType'],
                          "price": double.tryParse(rawPrice) ?? 0,
                        },
                      );

                      if (!context.mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cập nhật giá dịch vụ thành công!'), backgroundColor: Colors.green),
                        );
                      } else if (vm.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.redAccent),
                        );
                        vm.clearError();
                      }
                    },
                    child: const Text('Lưu'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== QUẢN LÝ PHÒNG TRỌ ====================
  Widget _buildRoomsTab(BuildContext context, AreaConfigViewModel vm) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showRoomFormDialog(context, vm, null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm phòng mới', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vm.rooms.length,
        itemBuilder: (context, index) {
          final room = vm.rooms[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text('T${room['floor']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Text('Phòng ${room['roomNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (String value) {
                          if (value == 'edit') {
                            _showRoomFormDialog(context, vm, room);
                          } else if (value == 'delete') {
                            _confirmDeleteRoom(context, vm, room['id'].toString(), room['roomNumber'].toString());
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(children: [Icon(Icons.edit, color: Colors.orange, size: 20), SizedBox(width: 8), Text('Sửa phòng')]),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text('Xóa phòng')]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(height: 1, thickness: 0.5)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Giá thuê: ', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                            Text('${formatCurrency(room['rentPrice'])}đ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Tiền cọc: ${formatCurrency(room['depositAmount'])}đ', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(Icons.aspect_ratio, '${formatCurrency(room['areaSize'])}m²', Colors.teal),
                      _buildBadge(Icons.people, 'Tối đa: ${room['maxOccupants']} người', Colors.purple),
                      _buildBadge(Icons.info_outline, _getStatusText(room['status']), _getStatusColor(room['status']), isFilled: true),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color, {bool isFilled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isFilled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isFilled ? null : Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isFilled ? Colors.white : color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isFilled ? Colors.white : color)),
        ],
      ),
    );
  }

  // --- CÁC HỘP THOẠI CHỨC NĂNG ---
  void _showRoomFormDialog(BuildContext context, AreaConfigViewModel vm, dynamic room) {
    final isEdit = room != null;

    // Nạp dữ liệu vào ViewModel
    if (isEdit) {
      vm.fillRoomForm(room);
    } else {
      vm.resetRoomForm();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Sửa thông tin phòng' : 'Thêm phòng mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: vm.floorController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tầng')),
              TextField(controller: vm.numberController, decoration: const InputDecoration(labelText: 'Số phòng (Ví dụ: 101)')),
              TextField(controller: vm.sizeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diện tích (m²)')),
              TextField(controller: vm.priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá thuê')),
              TextField(controller: vm.depositController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tiền cọc')),
              TextField(controller: vm.maxController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số người tối đa')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              // Bỏ popup Loading hoặc đóng Dialog ngay để UI không bị treo
              Navigator.pop(dialogContext);

              final payload = {
                "areaId": areaId,
                "floor": int.tryParse(vm.floorController.text) ?? 1,
                "roomNumber": vm.numberController.text.trim(),
                "areaSize": double.tryParse(vm.sizeController.text.replaceAll(',', '')) ?? 0.0,
                "rentPrice": double.tryParse(vm.priceController.text.replaceAll(',', '')) ?? 0,
                "depositAmount": double.tryParse(vm.depositController.text.replaceAll(',', '')) ?? 0,
                "maxOccupants": int.tryParse(vm.maxController.text) ?? 4,
                "status": isEdit ? room['status'] : "AVAILABLE"
              };

              final success = await vm.saveRoom(areaId, isEdit ? room['id'].toString() : null, payload);

              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật phòng thành công!'), backgroundColor: Colors.green));
              } else if (vm.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.redAccent));
                vm.clearError();
              }
            },
            child: const Text('Lưu lại'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(BuildContext context, AreaConfigViewModel vm, String roomId, String roomNumber) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tận gốc Phòng $roomNumber không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Đóng Dialog

              final success = await vm.deleteRoom(areaId, roomId);

              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phòng trọ thành công.')));
              } else if (vm.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.redAccent));
                vm.clearError();
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}