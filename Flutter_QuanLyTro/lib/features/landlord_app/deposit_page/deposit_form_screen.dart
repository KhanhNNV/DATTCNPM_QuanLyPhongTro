import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/response/room_model.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/app_colors.dart';
import 'view_models/deposit_form_view_model.dart';

class DepositFormScreen extends StatelessWidget {
  const DepositFormScreen({super.key});

  Future<void> _pickDate(BuildContext context, DepositFormViewModel vm) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: vm.expectedMoveInDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      vm.changeExpectedDate(date);
    }
  }

  void _showRoomSelectionDialog(BuildContext context, DepositFormViewModel vm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn phòng', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vm.rooms.length,
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final room = vm.rooms[index];
                return ListTile(
                  leading: const Icon(Icons.door_front_door, color: AppColors.primary),
                  title: Text('Phòng ${room.roomNumber}'),
                  subtitle: Text('Giá: ${room.rentPrice.toStringAsFixed(0)} đ'),
                  onTap: () {
                    vm.selectRoom(room);
                    Navigator.pop(context);
                  },
                  onLongPress: () => _showRoomDetails(context, room),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showRoomDetails(BuildContext context, RoomModel room) {
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

  Future<void> _handleSave(BuildContext context, DepositFormViewModel vm) async {
    FocusScope.of(context).unfocus();
    try {
      final newDeposit = await vm.saveDeposit();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo phiếu đặt cọc thành công'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, newDeposit);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DepositFormViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Tạo phiếu cọc'),
      body: vm.isLoading && vm.rooms.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
        key: vm.formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          children: [
            InkWell(
              onTap: () => _showRoomSelectionDialog(context, vm),
              onLongPress: () {
                if (vm.selectedRoom != null) {
                  _showRoomDetails(context, vm.selectedRoom!);
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
                  vm.selectedRoom != null ? 'Phòng ${vm.selectedRoom!.roomNumber}' : 'Vui lòng chọn phòng trống',
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
              controller: vm.tenantController,
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
              controller: vm.phoneController,
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
              controller: vm.depositController,
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
              onTap: () => _pickDate(context, vm),
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
                  vm.expectedMoveInDate == null
                      ? 'Chọn ngày'
                      : '${vm.expectedMoveInDate!.day}/${vm.expectedMoveInDate!.month}/${vm.expectedMoveInDate!.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: vm.noteController,
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
                text: 'XÁC NHẬN TẠO PHIẾU',
                isLoading: vm.isLoading,
                onPressed: () => _handleSave(context, vm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}