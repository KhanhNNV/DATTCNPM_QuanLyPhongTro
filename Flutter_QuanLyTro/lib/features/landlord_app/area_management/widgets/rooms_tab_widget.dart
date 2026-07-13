import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../room_detail_screen.dart';
import '../view_models/area_config_view_model.dart';
import '../view_models/room_detail_view_model.dart';

class RoomsTabWidget extends StatefulWidget {
  final String areaId;
  final AreaConfigViewModel vm;

  const RoomsTabWidget({super.key, required this.areaId, required this.vm});

  @override
  State<RoomsTabWidget> createState() => _RoomsTabWidgetState();
}

class _RoomsTabWidgetState extends State<RoomsTabWidget> {
  String _selectedFloor = 'All';
  String _selectedStatus = 'All';

  String formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = double.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,###', 'vi_VN').format(number).replaceAll(',', '.');
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'AVAILABLE': return 'Trống';
      case 'DEPOSITED': return 'Đã cọc';
      case 'RESERVED': return 'Giữ chỗ';
      case 'RENTED': return 'Đã thuê';
      case 'MAINTENANCE': return 'Bảo trì';
      default: return status ?? 'Không rõ';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'AVAILABLE': return Colors.green;
      case 'DEPOSITED': return Colors.orange;
      case 'RESERVED': return Colors.blueAccent;
      case 'RENTED': return Colors.redAccent;
      case 'MAINTENANCE': return Colors.grey;
      default: return Colors.black87;
    }
  }

  double parseMoney(String value) {
    return double.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    int maxFloor = 1;
    if (widget.vm.rooms.isNotEmpty) {
      maxFloor = widget.vm.rooms
          .map((room) => int.tryParse(room['floor'].toString()) ?? 1)
          .reduce((a, b) => a > b ? a : b);
    }

    List<String> filterFloors = List.generate(maxFloor, (index) => (index + 1).toString());

    if (_selectedFloor != 'All' && !filterFloors.contains(_selectedFloor)) {
      filterFloors.add(_selectedFloor);
      filterFloors.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    }

    final filteredRooms = widget.vm.rooms.where((room) {
      final matchFloor = _selectedFloor == 'All' || room['floor'].toString() == _selectedFloor;
      final matchStatus = _selectedStatus == 'All' || room['status'] == _selectedStatus;
      return matchFloor && matchStatus;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showRoomFormDialog(context, null, maxFloor),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        value: _selectedFloor,
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('Tất cả tầng')),
                          ...filterFloors.map((floor) => DropdownMenuItem(
                            value: floor,
                            child: Text('Tầng $floor'),
                          )),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFloor = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('Tất cả trạng thái')),
                          DropdownMenuItem(value: 'AVAILABLE', child: Text('Trống')),
                          DropdownMenuItem(value: 'DEPOSITED', child: Text('Đã cọc')),
                          DropdownMenuItem(value: 'RESERVED', child: Text('Giữ chỗ')),
                          DropdownMenuItem(value: 'RENTED', child: Text('Đã thuê')),
                          DropdownMenuItem(value: 'MAINTENANCE', child: Text('Bảo trì')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredRooms.isEmpty
                ? const Center(
              child: Text('Không tìm thấy phòng nào phù hợp.', style: TextStyle(color: Colors.grey)),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final room = filteredRooms[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => RoomDetailViewModel(areaId: widget.areaId)..fetchRoomAndMembers(room['id'].toString()),
                            child: RoomDetailScreen(
                              roomId: room['id'].toString(),
                              roomNumber: room['roomNumber'].toString(),
                            ),
                          ),
                        ),
                      );
                    },
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
                                    child: Text(
                                      'T${room['floor']}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Phòng ${room['roomNumber']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (String value) {
                                  if (value == 'edit') {
                                    _showRoomFormDialog(context, room, maxFloor);
                                  } else if (value == 'delete') {
                                    _confirmDeleteRoom(
                                      context,
                                      room['id'].toString(),
                                      room['roomNumber'].toString(),
                                    );
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
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tiền cọc: ${formatCurrency(room['depositAmount'])}đ',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
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
                  ),
                );
              },
            ),
          ),
        ],
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

  void _showRoomFormDialog(BuildContext context, dynamic room, int currentMaxFloor) {
    final isEdit = room != null;

    if (isEdit) {
      widget.vm.fillRoomForm(room);
    } else {
      widget.vm.resetRoomForm();
    }

    String currentFloor = widget.vm.floorController.text.trim();
    if (currentFloor.isEmpty) currentFloor = '1';

    final List<String> floorOptions = List.generate(currentMaxFloor + 1, (index) => (index + 1).toString());

    if (!floorOptions.contains(currentFloor)) {
      floorOptions.add(currentFloor);
      floorOptions.sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Sửa thông tin phòng' : 'Thêm phòng mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: currentFloor,
                decoration: const InputDecoration(
                  labelText: 'Tầng',
                  border: UnderlineInputBorder(),
                ),
                items: floorOptions.map((floor) {
                  return DropdownMenuItem(
                    value: floor,
                    child: Text('Tầng $floor'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) widget.vm.floorController.text = newValue;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.vm.numberController,
                decoration: const InputDecoration(labelText: 'Số phòng (Ví dụ: 101)'),
              ),
              TextField(
                controller: widget.vm.sizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Diện tích (m²)'),
              ),
              TextField(
                controller: widget.vm.priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Giá thuê',
                  suffixText: 'VNĐ',
                ),
              ),
              TextField(
                controller: widget.vm.depositController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: const InputDecoration(labelText: 'Tiền cọc'),
              ),
              TextField(
                controller: widget.vm.maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số người tối đa'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              final payload = {
                "areaId": widget.areaId,
                "floor": int.tryParse(widget.vm.floorController.text) ?? 1,
                "roomNumber": widget.vm.numberController.text.trim(),
                "areaSize": double.tryParse(widget.vm.sizeController.text) ?? 0.0,
                "rentPrice": parseMoney(widget.vm.priceController.text),
                "depositAmount": parseMoney(widget.vm.depositController.text),
                "maxOccupants": int.tryParse(widget.vm.maxController.text) ?? 4,
                "status": isEdit ? room['status'] : "AVAILABLE",
              };

              final success = await widget.vm.saveRoom(
                widget.areaId,
                isEdit ? room['id'].toString() : null,
                payload,
              );

              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật phòng thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (widget.vm.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.vm.errorMessage!),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                widget.vm.clearError();
              }
            },
            child: const Text('Lưu lại'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(BuildContext context, String roomId, String roomNumber) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa tận gốc Phòng $roomNumber không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final success = await widget.vm.deleteRoom(widget.areaId, roomId);

              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa phòng trọ thành công.')),
                );
              } else if (widget.vm.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.vm.errorMessage!),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                widget.vm.clearError();
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}