import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../data/models/response/room_model.dart';
import '../../../data/models/response/contract_create_response.dart';
import 'view_models/contract_create_view_model.dart';

class ContractCreateScreen extends StatelessWidget {
  const ContractCreateScreen({super.key});

  void _onSubmit(BuildContext context, ContractCreateViewModel vm) async {
    FocusScope.of(context).unfocus();
    try {
      final response = await vm.submitContract();
      if (response != null && context.mounted) {
        _showSuccessDialog(context, response);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, ContractCreateResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Thành công', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(response.message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tài khoản khách thuê:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('Tên đăng nhập: ${response.tenantUsername}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Mật khẩu: ${response.tenantRawPassword}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Đóng màn hình tạo HĐ
            },
            child: const Text('HOÀN TẤT', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required DateTime? initialDate, required Function(DateTime) onDateSelected}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) onDateSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ContractCreateViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Tạo hợp đồng mới'),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Form(
                key: vm.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TABS CHUYỂN ĐỔI CHẾ ĐỘ
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => vm.toggleMode(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: vm.isOcrMode ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('QUÉT CCCD (OCR)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: vm.isOcrMode ? Colors.white : Colors.grey[700])),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => vm.toggleMode(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !vm.isOcrMode ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('NHẬP THỦ CÔNG', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: !vm.isOcrMode ? Colors.white : Colors.grey[700])),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Thông tin phòng thuê', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 16),

                    // DROPDOWN CHỌN PHÒNG ĐÃ CỌC
                    if (vm.isFetchingRooms)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: DropdownButtonFormField<RoomModel>(
                          value: vm.selectedRoom,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Chọn phòng (Đang cọc)',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          hint: const Text('Danh sách phòng đang cọc'),
                          items: vm.depositedRooms.map((room) {
                            final formatCurrency = NumberFormat.decimalPattern();
                            return DropdownMenuItem(
                              value: room,
                              child: Text('Phòng ${room.roomNumber} (Cọc: ${formatCurrency.format(room.depositAmount)}đ)'),
                            );
                          }).toList(),
                          onChanged: (room) => vm.selectRoom(room),
                          validator: (v) => v == null ? 'Vui lòng chọn phòng' : null,
                        ),
                      ),

                    _buildTextField(vm.depositAmountController, 'Tiền cọc (VNĐ)', isNumber: true),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker(context, 'Bắt đầu', vm.startDate, (d) => vm.changeStartDate(d))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDatePicker(context, 'Kết thúc', vm.endDate, (d) => vm.changeEndDate(d))),
                      ],
                    ),
                    const Divider(height: 32),

                    Text(vm.isOcrMode ? 'Thông tin khách (OCR)' : 'Thông tin khách (Thủ công)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 16),
                    _buildTextField(vm.phoneController, 'SĐT Khách Thuê', isPhone: true),

                    if (vm.isOcrMode) ...[
                      _buildTextField(vm.templateIdController, 'ID Mẫu Hợp Đồng'),
                      const SizedBox(height: 4),
                      const Text('Ảnh mặt trước & mặt sau CCCD (Bắt buộc)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildImagePickerBox(context, 'Mặt trước', vm.frontImage, true, vm)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildImagePickerBox(context, 'Mặt sau', vm.backImage, false, vm)),
                        ],
                      ),
                    ] else ...[
                      _buildTextField(vm.tenantNameController, 'Họ và tên khách thuê'),
                      _buildTextField(vm.tenantIdCardNumberController, 'Số CCCD/CMND'),
                      _buildTextField(vm.tenantHometownController, 'Quê quán / Địa chỉ thường trú'),
                      _buildDatePicker(context, 'Ngày sinh', vm.tenantDob, (d) => vm.changeTenantDob(d)),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 8)],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _onSubmit(context, vm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(vm.isOcrMode ? 'TẠO HỢP ĐỒNG (OCR)' : 'LƯU HỢP ĐỒNG (THỦ CÔNG)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : (isNumber ? TextInputType.number : TextInputType.text),
        style: const TextStyle(fontSize: 14, height: 1.4),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          alignLabelWithHint: true,
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập $label' : null,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime? date, Function(DateTime) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => _selectDate(context, initialDate: date, onDateSelected: onSelect),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[400]!)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date == null ? label : DateFormat('dd/MM/yyyy').format(date), style: TextStyle(color: date == null ? Colors.grey[600] : Colors.black87, fontSize: 14)),
              const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerBox(BuildContext context, String title, File? imageFile, bool isFront, ContractCreateViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Chụp ảnh'), onTap: () { Navigator.pop(ctx); vm.pickImage(isFront: isFront, fromCamera: true); }),
                    ListTile(leading: const Icon(Icons.photo_library), title: const Text('Chọn từ thư viện'), onTap: () { Navigator.pop(ctx); vm.pickImage(isFront: isFront, fromCamera: false); }),
                  ],
                ),
              ),
            );
          },
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid)),
            child: imageFile != null
                ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(imageFile, fit: BoxFit.cover)),
                Positioned(top: 4, right: 4, child: InkWell(onTap: () => vm.removeImage(isFront: isFront), child: const CircleAvatar(radius: 12, backgroundColor: Colors.redAccent, child: Icon(Icons.close, size: 14, color: Colors.white))))
              ],
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, color: Colors.grey, size: 28),
                SizedBox(height: 8),
                Text('Tải ảnh', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}