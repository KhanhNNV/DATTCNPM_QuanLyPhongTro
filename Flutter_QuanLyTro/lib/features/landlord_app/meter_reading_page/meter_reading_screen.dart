import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/meter_reading_page/view_models/meter_reading_view_model.dart';
import 'package:flutter_quanlytro/features/landlord_app/meter_reading_page/view_models/room_reading_ui_model.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';

class MeterReadingScreen extends StatefulWidget {
  const MeterReadingScreen({super.key});

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  final MeterReadingViewModel _viewModel = MeterReadingViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadMeterReadings();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _viewModel.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      _viewModel.changeMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(title: 'Chốt điện nước'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Column(
            children: [
              // --- Header chọn Tháng/Năm ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Kỳ hóa đơn: Tháng ${_viewModel.selectedMonth.month}/${_viewModel.selectedMonth.year}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _selectMonth(context),
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('Đổi kỳ'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Colors.black12),

              // --- Danh sách phòng ---
              Expanded(
                child: _viewModel.isLoading && _viewModel.roomList.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                    : _viewModel.roomList.isEmpty
                    ? const Center(child: Text('Không có dữ liệu phòng cho kỳ này.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _viewModel.roomList.length,
                  itemBuilder: (context, index) {
                    final room = _viewModel.roomList[index];
                    return _buildRoomCard(room);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(RoomReadingUiModel room) {
    if (!room.isElecByIndex && !room.isWaterByIndex) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.meeting_room, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Phòng ${room.roomNumber}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                if (room.elecReadingId != null || room.waterReadingId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Đã có dữ liệu', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, thickness: 0.5),
            ),

            if (room.isElecByIndex) ...[
              _buildInputRow(
                icon: Icons.bolt,
                iconColor: Colors.orange,
                title: 'Chỉ số Điện',
                oldIndex: room.elecOldIndex,
                controller: room.elecController,
              ),
              const SizedBox(height: 16),
            ],

            if (room.isWaterByIndex) ...[
              _buildInputRow(
                icon: Icons.water_drop,
                iconColor: Colors.blue,
                title: 'Chỉ số Nước',
                oldIndex: room.waterOldIndex,
                controller: room.waterController,
              ),
              const SizedBox(height: 16),
            ],

            Align(
              alignment: Alignment.centerRight,
              child: CustomButton(
                text: 'Lưu',
                isLoading: _viewModel.isLoading,
                onPressed: () async {
                  FocusScope.of(context).unfocus();

                  final success = await _viewModel.saveSingleRoom(room);
                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã lưu chỉ số phòng ${room.roomNumber} thành công!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập đầy đủ chỉ số mới!'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int oldIndex,
    required TextEditingController controller,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 2),
              Text('Số cũ: $oldIndex', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Số mới',
                labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}