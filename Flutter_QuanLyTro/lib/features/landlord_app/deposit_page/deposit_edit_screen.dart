import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../core/utils/currency_input_formatter.dart';
import 'view_models/deposit_edit_view_model.dart';

class DepositEditScreen extends StatelessWidget {
  const DepositEditScreen({super.key});

  Future<void> _pickDate(BuildContext context, DepositEditViewModel vm) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
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
    if (date != null) vm.changeExpectedDate(date);
  }

  Future<void> _handleUpdate(BuildContext context, DepositEditViewModel vm) async {
    FocusScope.of(context).unfocus();
    try {
      await vm.saveUpdate();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Trả về true báo hiệu cập nhật thành công
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING': return 'Chờ xử lý';
      case 'COMPLETED': return 'Đã hoàn thành';
      case 'CANCELLED': return 'Đã hủy cọc';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DepositEditViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Chỉnh sửa phiếu cọc'),
      body: Form(
        key: vm.formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin phòng (Không cho sửa)
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Phòng',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[200], // Màu xám báo hiệu readonly
              ),
              child: Text(
                'Phòng ${vm.roomNumber}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),


            DropdownButtonFormField<String>(
              value: vm.selectedStatus,
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: vm.statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusText(status), style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: vm.changeStatus,
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
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
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
                text: 'LƯU THAY ĐỔI',
                isLoading: vm.isLoading,
                onPressed: () => _handleUpdate(context, vm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}