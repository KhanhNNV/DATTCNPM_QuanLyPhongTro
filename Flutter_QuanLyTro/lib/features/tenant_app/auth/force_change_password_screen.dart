import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/tenant_app/auth/view_models/force_change_password_view_model.dart';
import 'package:flutter_quanlytro/features/tenant_app/main_layout/tenant_main_layout_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../main_layout/view_models/tenant_main_layout_view_model.dart';

class ForceChangePasswordScreen extends StatelessWidget {
  const ForceChangePasswordScreen({super.key});

  void _handleSubmit(BuildContext context, ForceChangePasswordViewModel vm) async {
    FocusScope.of(context).unfocus();
    final success = await vm.changePassword();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
      );


      Provider.of<TenantMainLayoutViewModel>(context, listen: false).fetchInitialData();


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TenantMainLayoutScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Có lỗi xảy ra'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForceChangePasswordViewModel>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Cập nhật mật khẩu', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Chào mừng bạn lần đầu đăng nhập!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vì lý do bảo mật, vui lòng thay đổi mật khẩu mặc định trước khi tiếp tục sử dụng ứng dụng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),


                TextField(
                  controller: viewModel.oldPasswordController,
                  obscureText: viewModel.obscureOldPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại (Mặc định)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.password),
                    suffixIcon: IconButton(
                      icon: Icon(
                        viewModel.obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: viewModel.toggleOldPasswordVisibility,
                    ),
                  ),
                ),
                const SizedBox(height: 16),


                TextField(
                  controller: viewModel.newPasswordController,
                  obscureText: viewModel.obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        viewModel.obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: viewModel.toggleNewPasswordVisibility,
                    ),
                  ),
                ),
                const SizedBox(height: 16),


                TextField(
                  controller: viewModel.confirmPasswordController,
                  obscureText: viewModel.obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.check_circle_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        viewModel.obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: viewModel.toggleConfirmPasswordVisibility,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: viewModel.isLoading ? null : () => _handleSubmit(context, viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: viewModel.isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text(
                      'Xác nhận & Tiếp tục',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}