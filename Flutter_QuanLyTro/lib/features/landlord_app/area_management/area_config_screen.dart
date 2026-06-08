import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'view_models/area_config_view_model.dart';

class AreaConfigScreen extends StatefulWidget {
  final String areaId;
  const AreaConfigScreen({super.key, required this.areaId});

  @override
  State<AreaConfigScreen> createState() => _AreaConfigScreenState();
}

class _AreaConfigScreenState extends State<AreaConfigScreen> with SingleTickerProviderStateMixin {
  final AreaConfigViewModel _viewModel = AreaConfigViewModel();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.addListener(_onViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadAreaDetails(widget.areaId);
    });
  }

  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!), backgroundColor: Colors.redAccent),
      );
      _viewModel.clearError();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  String formatNumber(dynamic value) {
    if (value == null) return '';

    final number = double.tryParse(value.toString());

    if (number == null) return value.toString();

    if (number == number.toInt()) {
      return number.toInt().toString();
    }

    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tinh chỉnh Khu trọ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bolt), text: 'Dịch vụ'),
            Tab(icon: Icon(Icons.door_front_door), text: 'Phòng trọ'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.services.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildServicesTab(),
              _buildRoomsTab(),
            ],
          );
        },
      ),
    );
  }

  // ==================== QUẢN LÝ DỊCH VỤ ====================
  Widget _buildServicesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _viewModel.services.length,
      itemBuilder: (context, index) {
        final service = _viewModel.services[index];
        final priceController = TextEditingController(text: formatNumber(service['price']));

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
                      final success = await _viewModel.saveService(
                        widget.areaId,
                        service['id'],
                        {
                          "name": service['name'],
                          "calcType": service['calcType'],
                          "price": double.tryParse(priceController.text) ?? 0,
                        },
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cập nhật giá dịch vụ thành công!'),
                          ),
                        );
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
  Widget _buildRoomsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showRoomFormDialog(null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm phòng mới', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _viewModel.rooms.length,
        itemBuilder: (context, index) {
          final room = _viewModel.rooms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text('T${room['floor']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text('Phòng ${room['roomNumber']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giá: ${room['rentPrice']}đ'),
                  Text('Diện tích: ${room['areaSize']}m²'),
                Text()
                final priceController = TextEditingController(text: isEdit ? room['rentPrice'].toString() : '');
          final depositController = TextEditingController(text: isEdit ? room['depositAmount'].toString() : '');
          final maxController = TextEditingController(text: isEdit ? room['maxOccupants'].toString() : '4');
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showRoomFormDialog(room)),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteRoom(room['id'].toString(), room['roomNumber'].toString()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Hộp thoại Thêm/Sửa phòng dựa trên RoomRequest DTO
  void _showRoomFormDialog(dynamic room) {
    final isEdit = room != null;
    final floorController = TextEditingController(text: isEdit ? room['floor'].toString() : '1');
    final numberController = TextEditingController(text: isEdit ? room['roomNumber'] : '');
    final sizeController = TextEditingController(text: isEdit ? room['areaSize'].toString() : '');
    final priceController = TextEditingController(text: isEdit ? room['rentPrice'].toString() : '');
    final depositController = TextEditingController(text: isEdit ? room['depositAmount'].toString() : '');
    final maxController = TextEditingController(text: isEdit ? room['maxOccupants'].toString() : '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa thông tin phòng' : 'Thêm phòng mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: floorController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tầng')),
              TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Số phòng (Ví dụ: 101)')),
              TextField(controller: sizeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diện tích (m²)')),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá thuê')),
              TextField(controller: depositController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tiền cọc')),
              TextField(controller: maxController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số người mớ đa')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                "areaId": widget.areaId,
                "floor": int.tryParse(floorController.text) ?? 1,
                "roomNumber": numberController.text.trim(),
                "areaSize": double.tryParse(sizeController.text) ?? 0.0,
                "rentPrice": double.tryParse(priceController.text) ?? 0,
                "depositAmount": double.tryParse(depositController.text) ?? 0,
                "maxOccupants": int.tryParse(maxController.text) ?? 4,
                "status": isEdit ? room['status'] : "AVAILABLE"
              };
              final success = await _viewModel.saveRoom(widget.areaId, isEdit ? room['id'].toString() : null, payload);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật phòng thành công!')));
              }
            },
            child: const Text('Lưu lại'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(String roomId, String roomNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tận gốc Phòng $roomNumber không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final success = await _viewModel.deleteRoom(widget.areaId, roomId);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phòng trọ thành công.')));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}