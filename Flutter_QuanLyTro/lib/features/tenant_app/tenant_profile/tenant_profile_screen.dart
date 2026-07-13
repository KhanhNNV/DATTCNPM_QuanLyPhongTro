import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/tenant_app/tenant_profile/view_models/tenant_profile_view_model.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';

class TenantProfileScreen extends StatelessWidget {
  const TenantProfileScreen({super.key});

  void _handleChangePassword(BuildContext context, TenantProfileViewModel vm) async {
    FocusScope.of(context).unfocus();
    final success = await vm.changePassword();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Có lỗi xảy ra'), backgroundColor: Colors.red),
      );
    }
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Chưa cập nhật' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantProfileViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: viewModel.isFetching
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : viewModel.errorMessage != null && viewModel.currentUser == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: ${viewModel.errorMessage}', style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: viewModel.fetchProfile, child: const Text('Thử lại')),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_ind_outlined, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Thông tin lưu trú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),

                    _buildInfoRow(Icons.badge_outlined, 'Họ và tên', viewModel.currentUser?.fullName ?? ''),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', viewModel.currentUser?.phone ?? ''),
                    _buildInfoRow(Icons.credit_card, 'Số CCCD/CMND', viewModel.currentUser?.idCardNumber ?? ''),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Ngày sinh', viewModel.displayDate(viewModel.selectedDob)),
                    _buildInfoRow(Icons.home_outlined, 'Quê quán', viewModel.currentUser?.hometown ?? ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Đổi mật khẩu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: viewModel.oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder(), prefixIcon: Icon(Icons.password)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: viewModel.newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: viewModel.confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', border: OutlineInputBorder(), prefixIcon: Icon(Icons.check_circle_outline)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: viewModel.isUpdatingPassword ? null : () => _handleChangePassword(context, viewModel),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: viewModel.isUpdatingPassword
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Đổi mật khẩu', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}