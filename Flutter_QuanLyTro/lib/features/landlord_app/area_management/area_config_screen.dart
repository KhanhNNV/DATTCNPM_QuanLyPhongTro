import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import 'view_models/area_config_view_model.dart';
import 'package:intl/intl.dart';

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

  String formatCurrency(dynamic value) {
    if (value == null) return '0';

    final number = double.tryParse(value.toString()) ?? 0;

    return NumberFormat('#,###', 'vi_VN')
        .format(number)
        .replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
        appBar: CustomAppBar(
          title: 'Tinh chỉnh Khu trọ',
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
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
        final priceController = TextEditingController(text: formatCurrency(service['price']));

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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Dòng 1: Header (Tầng, Tên phòng, Menu 3 chấm) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                                'T${room['floor']}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                              'Phòng ${room['roomNumber']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ],
                      ),

                      // Nút 3 chấm (PopupMenuButton)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (String value) {
                          if (value == 'edit') {
                            _showRoomFormDialog(room);
                          } else if (value == 'delete') {
                            _confirmDeleteRoom(room['id'].toString(), room['roomNumber'].toString());
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text('Sửa phòng'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                SizedBox(width: 8),
                                Text('Xóa phòng'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, thickness: 0.5),
                  ),

                  // --- Dòng 2: Thông tin Giá và Cọc (Text thường, nhấn mạnh giá) ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Giá thuê: ',
                              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                            ),
                            Text(
                              '${formatCurrency(room['rentPrice'])}đ',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Tiền cọc: ${formatCurrency(room['depositAmount'])}đ',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Dòng 3: Hiển thị các Badge phụ (Diện tích, Người, Trạng thái) ---
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(Icons.aspect_ratio, '${formatCurrency(room['areaSize'])}m²', Colors.teal),
                      _buildBadge(Icons.people, 'Tối đa: ${room['maxOccupants']} người', Colors.purple),
                      _buildBadge(
                          Icons.info_outline,
                          _getStatusText(room['status']),
                          _getStatusColor(room['status']),
                          isFilled: true
                      ),
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
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isFilled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  // Chuyển đổi mã trạng thái sang Text Tiếng Việt
  String _getStatusText(String? status) {
    switch (status) {
      case 'AVAILABLE': return 'Trống';
      case 'DEPOSITED': return 'Đã cọc';
      case 'RENTED': return 'Đã thuê';
      case 'MAINTENANCE': return 'Bảo trì';
      default: return status ?? 'Không rõ';
    }
  }

  // Chuyển đổi mã trạng thái sang Màu sắc
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'AVAILABLE': return Colors.green;
      case 'DEPOSITED': return Colors.redAccent;
      case 'RENTED': return Colors.redAccent;
      case 'MAINTENANCE': return Colors.orange;
      default: return Colors.grey;
    }
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
              TextField(controller: maxController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số người tối đa')),
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