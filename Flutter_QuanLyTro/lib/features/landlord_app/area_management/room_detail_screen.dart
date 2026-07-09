import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import 'view_models/room_detail_view_model.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  final String roomNumber;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomNumber,
  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phòng $roomNumber'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<RoomDetailViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.room == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null && vm.room == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => vm.fetchRoomAndMembers(roomId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final room = vm.room!;
          final contract = vm.activeContract;
          final members = contract?.members ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Thông tin phòng'),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Số phòng', value: room.roomNumber ?? ''),
                        const Divider(),
                        _InfoRow(
                          label: 'Trạng thái',
                          value: _getStatusText(room.status),
                          valueColor: _getStatusColor(room.status),
                          isBold: true,
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Giá thuê',
                          value: '${formatCurrency(room.rentPrice)} đ',
                          valueColor: Colors.blue,
                          isBold: true,
                        ),
                        const Divider(),
                        _InfoRow(label: 'Tiền cọc', value: '${formatCurrency(room.depositAmount)} đ'),
                        const Divider(),
                        _InfoRow(label: 'Số người tối đa', value: '${room.maxOccupants ?? 0} người'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle(title: 'Thành viên'),
                    if (contract != null && members.length < (room.maxOccupants ?? 99))
                      TextButton.icon(
                        onPressed: () => _showAddMemberDialog(context, vm),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Thêm người'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      )
                  ],
                ),
                if (contract == null)
                  _buildEmptyState('Phòng đang trống, chưa có hợp đồng/thành viên.')
                else if (members.isEmpty)
                  _buildEmptyState('Chưa có thành viên nào được khai báo.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isRepresentative = member.fullName == contract.tenantName;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isRepresentative ? AppColors.primary : Colors.transparent, width: 1.5),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRepresentative ? AppColors.primary : Colors.grey.shade300,
                            child: Icon(Icons.person, color: isRepresentative ? Colors.white : Colors.grey.shade700),
                          ),
                          title: Row(
                            children: [
                              Text(member.fullName.isNotEmpty ? member.fullName : 'Chưa rõ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (isRepresentative) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Đại diện', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                          subtitle: Text('SĐT: ${member.phone ?? '...'}'),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  // --- WIDGET TIỆN ÍCH DÙNG CHO HỘP THOẠI ---
  Widget _buildDialogTextField(TextEditingController controller, String label, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 14, height: 1.4),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, RoomDetailViewModel vm) {
    vm.clearMemberForm();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm thành viên mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          backgroundColor: Colors.grey[50], // Nền hơi xám nhẹ cho đồng bộ
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(vm.nameController, 'Họ và tên *'),
                _buildDialogTextField(vm.phoneController, 'Số điện thoại *', type: TextInputType.phone),
                _buildDialogTextField(vm.idCardController, 'Số CMND/CCCD *', type: TextInputType.number),

                // Ô DatePicker
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: vm.dobController,
                    builder: (context, value, child) {
                      final bool isHint = value.text.isEmpty;

                      // Chuyển đổi định dạng yyyy-MM-dd sang dd/MM/yyyy chỉ để hiển thị
                      String displayDate = value.text;
                      if (!isHint) {
                        try {
                          final parsedDate = DateFormat('yyyy-MM-dd').parse(value.text);
                          displayDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                        } catch (_) {
                          // Nếu lỗi parse, giữ nguyên text gốc
                        }
                      }

                      return InkWell(
                        onTap: () async {
                          DateTime initialDate = DateTime(2000); // Mặc định mở ở năm 2000 cho dễ chọn tuổi
                          if (!isHint) {
                            try {
                              initialDate = DateFormat('yyyy-MM-dd').parse(value.text);
                            } catch (_) {}
                          }

                          final DateTime? pickedDate = await showDatePicker(
                            context: dialogContext,
                            initialDate: initialDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            // Ghi đè vào controller (Định dạng yyyy-MM-dd để đẩy lên Backend)
                            vm.dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isHint ? 'Ngày sinh * (VD: 31/12/2000)' : displayDate,
                                style: TextStyle(
                                  color: isHint ? Colors.grey[600] : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                _buildDialogTextField(vm.hometownController, 'Quê quán'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                if (vm.nameController.text.isEmpty || vm.phoneController.text.isEmpty || vm.idCardController.text.isEmpty || vm.dobController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ các trường bắt buộc (*)')));
                  return;
                }

                Navigator.pop(dialogContext);

                final success = await vm.addMember();

                if (!context.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thành viên thành công!'), backgroundColor: Colors.green));
                } else if (vm.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  vm.clearError();
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _InfoRow({required this.label, required this.value, this.valueColor, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }
}