import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/setting_page/view_models/settings_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/request/user_update_request.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _hometownController;

  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _hometownController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().fetchCurrentUser().then((_) {
        final user = context.read<SettingsViewModel>().currentUser;
        if (user != null) {
          _fullNameController.text = user.fullName ?? '';
          _phoneController.text = user.phone ?? '';
          _hometownController.text = user.hometown ?? '';

          // Xử lý gán ngày sinh nếu có từ backend (Giả sử BE trả về yyyy-MM-dd)
          if (user.dob != null && user.dob!.isNotEmpty) {
            try {
              _selectedDob = DateTime.parse(user.dob!);
            } catch (e) {
              _selectedDob = null;
            }
          }
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  // Hàm chọn ngày sinh
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 18)), // Mặc định 18 tuổi
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  // Format Date sang dạng yyyy-MM-dd để gửi cho Spring Boot (LocalDate)
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Format hiển thị cho người dùng (dd/MM/yyyy)
  String _displayDate(DateTime? date) {
    if (date == null) return 'Chọn ngày sinh';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _handleUpdate() async {
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày sinh')),
      );
      return;
    }

    final viewModel = context.read<SettingsViewModel>();
    final request = UserUpdateRequest(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
      hometown: _hometownController.text.trim(),
      dob: _formatDate(_selectedDob), // Gửi dạng yyyy-MM-dd
    );

    final success = await viewModel.updateUserInfo(request);

    if (mounted) {
      if (success) {
        // Clear password sau khi cập nhật thành công (an toàn)
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage ?? 'Có lỗi xảy ra')),
        );
      }
    }
  }

  void _handleLogout() {
    context.read<SettingsViewModel>().logout();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã nhấn Đăng xuất')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông tin'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null && viewModel.currentUser == null) {
            return Center(child: Text('Lỗi: ${viewModel.errorMessage}'));
          }

          return SingleChildScrollView(
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
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _phoneController,
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
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh (dd/MM/yyyy)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _displayDate(_selectedDob),
                      style: TextStyle(
                        color: _selectedDob == null ? Colors.grey : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _hometownController,
                  decoration: const InputDecoration(
                    labelText: 'Quê quán',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
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
                    onPressed: viewModel.isLoading ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: viewModel.isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                        : const Text('Cập nhật thông tin', style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}