import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quanlytro/features/landlord_app/setting_page/view_models/settings_viewmodel.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _selectDate(BuildContext context, SettingsViewModel vm) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != vm.selectedDob) {
      vm.updateDob(picked);
    }
  }

  void _handleUpdate(BuildContext context, SettingsViewModel vm) async {
    if (vm.selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày sinh')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final success = await vm.updateUserInfo();

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.errorMessage ?? 'Có lỗi xảy ra')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Lắng nghe liên tục sự thay đổi từ SettingsViewModel
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông tin', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: viewModel.isLoading && viewModel.currentUser == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : viewModel.errorMessage != null && viewModel.currentUser == null
          ? Center(child: Text('Lỗi: ${viewModel.errorMessage}'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: viewModel.fullNameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: viewModel.phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Nút chọn ngày sinh
            InkWell(
              onTap: () => _selectDate(context, viewModel),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh (dd/MM/yyyy)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  viewModel.displayDate(viewModel.selectedDob),
                  style: TextStyle(
                    color: viewModel.selectedDob == null ? Colors.grey : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: viewModel.hometownController,
              decoration: const InputDecoration(
                labelText: 'Quê quán',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: viewModel.passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới (Để trống nếu không đổi)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: viewModel.isLoading ? null : () => _handleUpdate(context, viewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: viewModel.isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : const Text('Cập nhật thông tin', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}