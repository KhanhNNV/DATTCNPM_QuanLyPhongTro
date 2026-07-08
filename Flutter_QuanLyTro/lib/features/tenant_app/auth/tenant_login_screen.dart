import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../main_layout/tenant_main_layout_screen.dart';
import '../main_layout/view_models/tenant_main_layout_view_model.dart';
import 'view_models/tenant_login_view_model.dart';

class TenantLoginScreen extends StatefulWidget {
  const TenantLoginScreen({super.key});

  @override
  State<TenantLoginScreen> createState() => _TenantLoginScreenState();
}

class _TenantLoginScreenState extends State<TenantLoginScreen> {
  bool _isObscure = true;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TenantLoginViewModel _viewModel = TenantLoginViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
      _viewModel.clearError();
    }
  }

  void _handleLogin() {
    _viewModel.login(
      _phoneController.text,
      _passwordController.text,
      onSuccess: () {
        Provider.of<TenantMainLayoutViewModel>(context, listen: false).fetchInitialData();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TenantMainLayoutScreen(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chào mừng bạn đến với Phòng Của Tôi.\nHãy nhập số điện thoại và mật khẩu mà chủ trọ đã cung cấp cho bạn.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_viewModel.isLoading,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        hintText: 'Nhập số điện thoại của bạn',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      enabled: !_viewModel.isLoading,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _isObscure = !_isObscure),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _viewModel.isLoading ? null : () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _viewModel.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _viewModel.isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}