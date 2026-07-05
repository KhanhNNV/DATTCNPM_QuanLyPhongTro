import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'view_models/contract_update_view_model.dart';

class ContractUpdateScreen extends StatelessWidget {
  const ContractUpdateScreen({super.key});

  void _onSubmit(BuildContext context, ContractUpdateViewModel vm) async {
    FocusScope.of(context).unfocus();
    try {
      await vm.submitUpdate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật hợp đồng thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
      );
    }
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
    final vm = context.watch<ContractUpdateViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Sửa hợp đồng (Nháp)'),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: vm.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin phòng thuê', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 16),

                    // Tên phòng hiển thị read-only (Không cho đổi phòng)
                    TextFormField(
                      initialValue: 'Phòng ${vm.currentContract.roomNumber}',
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Phòng',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(vm.depositAmountController, 'Tiền cọc (VNĐ)', isNumber: true),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker(context, 'Bắt đầu', vm.startDate, (d) => vm.changeStartDate(d))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDatePicker(context, 'Kết thúc', vm.endDate, (d) => vm.changeEndDate(d))),
                      ],
                    ),
                    const Divider(height: 32),

                    const Text('Thông tin khách thuê', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 16),
                    _buildTextField(vm.tenantNameController, 'Họ và tên khách thuê'),
                    _buildTextField(vm.tenantIdCardNumberController, 'Số CCCD/CMND'),
                    _buildTextField(vm.tenantHometownController, 'Quê quán / Địa chỉ thường trú'),
                    _buildDatePicker(context, 'Ngày sinh', vm.tenantDob, (d) => vm.changeTenantDob(d)),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 8)]),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _onSubmit(context, vm),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('CẬP NHẬT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label, filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
}