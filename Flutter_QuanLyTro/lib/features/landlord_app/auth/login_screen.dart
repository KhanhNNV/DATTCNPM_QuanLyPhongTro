import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/auth/register_screen.dart';
import 'package:flutter_quanlytro/features/landlord_app/auth/view_models/login_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../home_page/home_page_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LoginViewModel _viewModel = LoginViewModel();


  @override
  void initState() {
    super.initState();
    // Lắng nghe ViewModel để hiển thị thông báo lỗi (nếu có)
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    // Nếu ViewModel có lỗi, hiển thị SnackBar và xóa lỗi đi để không hiện lại
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
    // Gọi hàm login từ ViewModel, truyền UI callback vào
    _viewModel.login(
      _phoneController.text,
      _passwordController.text,
      onSuccess: () {
        // Chuyển hướng sang trang chủ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePageScreen(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Sử dụng ListenableBuilder để chỉ vẽ lại UI khi ViewModel thay đổi (ví dụ: đang loading)
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng đăng nhập để tiếp tục.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),

                  // Nhập SDT
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_viewModel.isLoading, // Khóa ô nhập khi đang tải
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'Nhập số điện thoại của bạn',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nhập Pass
                  TextField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    enabled: !_viewModel.isLoading, // Khóa ô nhập khi đang tải
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _viewModel.isLoading ? null : () {},
                      child: const Text('Quên mật khẩu?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _viewModel.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _viewModel.isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Đăng nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.black54, fontSize: 15)),
                      GestureDetector(
                        onTap: _viewModel.isLoading
                            ? null
                            : () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                        },
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}