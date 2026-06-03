import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../../data/providers/user_provider.dart';
import '../../../../data/models/user_model.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  final UserProvider _userProvider = UserProvider();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu user ngay khi màn hình vừa mở lên
    _fetchUserData();
  }

  // Hàm gọi API
  Future<void> _fetchUserData() async {
    // 1. Bật trạng thái loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. Gọi Provider (bên trong ApiClient sẽ tự động lo vụ kẹp Token / Refresh Token)
      final user = await _userProvider.getCurrentUser();

      // 3. Cập nhật UI khi thành công
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      print("Đã gọi thành công API lấy thông tin: ${user.fullName}");
    } catch (e) {
      // 4. Báo lỗi nếu API sập hoặc hết hẳn phiên đăng nhập
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Không cần dùng AppBar ở đây nữa vì MainLayoutScreen đã bao bọc nó rồi
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // Xử lý 3 trạng thái của màn hình: Đang tải / Bị lỗi / Thành công
        child: _isLoading
            ? const CircularProgressIndicator(color: AppColors.primary) // Đang tải
            : _errorMessage != null
            ? Column( // Bị lỗi
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Lỗi: $_errorMessage', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUserData,
              child: const Text('Thử lại'),
            ),
          ],
        )
            : Column( // Thành công
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hiển thị lời chào
            Text(
              "Xin chào ${_currentUser?.fullName ?? 'bạn'} 👋",
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary
              ),
            ),
            const SizedBox(height: 40),

            // Nút bấm test gọi lại API
            ElevatedButton.icon(
              onPressed: _fetchUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('Test Gọi lại API'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}