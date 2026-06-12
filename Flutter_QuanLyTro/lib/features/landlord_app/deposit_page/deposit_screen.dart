import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/deposit_page/view_models/deposit_view_model.dart';

import '../../../../data/models/request/deposit_create_request.dart';
import '../../../data/models/response/room_model.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/app_colors.dart';

class DepositScreen extends StatefulWidget {
  final String areaId;

  const DepositScreen({
    super.key,
    required this.areaId,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final DepositViewModel vm = DepositViewModel();

  final _formKey = GlobalKey<FormState>();

  final _tenantController = TextEditingController();
  final _phoneController = TextEditingController();
  final _depositController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _expectedMoveInDate;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    await vm.loadRooms(widget.areaId);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _expectedMoveInDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Màu nút/chọn ngày
              onPrimary: Colors.black87, // Màu chữ trên nút
              onSurface: Colors.black, // Màu chữ lịch
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _expectedMoveInDate = date;
      });
    }
  }

  void _showRoomSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chọn phòng', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                'Nhấn giữ để xem chi tiết phòng',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vm.rooms.length,
              separatorBuilder: (context, index) {
                return const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.black12,
                );
              },
              itemBuilder: (context, index) {
                final room = vm.rooms[index];
                return ListTile(
                  leading: const Icon(Icons.door_front_door, color: AppColors.primary),
                  title: Text('Phòng ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Giá: ${room.rentPrice.toStringAsFixed(0)} đ'),
                  onTap: () {
                    setState(() {
                      vm.selectRoom(room);
                      _depositController.text = room.depositAmount.toStringAsFixed(0);
                    });
                    Navigator.pop(context);
                  },
                  onLongPress: (){
                    _showRoomDetails(room);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showRoomDetails(RoomModel room) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Chi tiết Phòng ${room.roomNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tầng:', '${room.floor}'),
              _buildDetailRow('Diện tích:', '${room.areaSize} m²'),
              _buildDetailRow('Số người tối đa:', '${room.maxOccupants ?? 0} người'),
              const Divider(),
              _buildDetailRow('Giá thuê:', '${room.rentPrice.toStringAsFixed(0)} đ', isHighlight: true),
              _buildDetailRow('Tiền cọc:', '${room.depositAmount.toStringAsFixed(0)} đ', isHighlight: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: Colors.black87)),
            )
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.redAccent : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (vm.selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_expectedMoveInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày dự kiến vào ở'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    try {
      final request = DepositCreateRequest(
        roomId: vm.selectedRoom!.id,
        phone: _phoneController.text.trim(),
        tenantFullName: _tenantController.text.trim(),
        depositAmount: double.parse(_depositController.text.trim()),
        expectedMoveInDate: _expectedMoveInDate!.toIso8601String().split('T').first,
        note: _noteController.text.trim(),
      );

      await vm.createDeposit(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo phiếu đặt cọc thành công'), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _phoneController.dispose();
    _depositController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Cọc giữ chỗ'),
      body: vm.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          children: [
            InkWell(
              onTap: _showRoomSelectionDialog,
              onLongPress: () {
                if (vm.selectedRoom != null) {
                  _showRoomDetails(vm.selectedRoom!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn phòng trước')),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Phòng (Nhấn chọn - Ấn giữ xem chi tiết)',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  vm.selectedRoom != null ? 'Phòng ${vm.selectedRoom!.roomNumber}' : 'Vui lòng chọn phòng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: vm.selectedRoom != null ? FontWeight.bold : FontWeight.normal,
                    color: vm.selectedRoom != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _tenantController,
              decoration: InputDecoration(
                labelText: 'Tên khách thuê',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _depositController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tiền cọc',
                suffixText: 'đ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Ngày dự kiến vào ở',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.calendar_today, size: 20),
                ),
                child: Text(
                  _expectedMoveInDate == null
                      ? 'Chọn ngày'
                      : '${_expectedMoveInDate!.day}/${_expectedMoveInDate!.month}/${_expectedMoveInDate!.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              width: double.infinity,
              child: CustomButton(
                text: 'TẠO PHIẾU ĐẶT CỌC',
                isLoading: vm.isLoading,
                onPressed: _saveDeposit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}