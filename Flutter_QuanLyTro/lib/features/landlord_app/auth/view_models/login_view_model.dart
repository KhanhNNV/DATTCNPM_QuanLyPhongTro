import 'package:flutter/material.dart';
import '../../../../data/repository/auth_repository.dart';
import '../../../../data/repository/user_repository.dart';
import '../../../../data/models/response/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authProvider = AuthRepository();

  // Trạng thái Loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Trạng thái Lỗi
  String? _errorMessage;
  String? get errorMessage => _errorMessage;



  // Hàm xử lý đăng nhập
  Future<void> login(String phone, String password, {required VoidCallback onSuccess}) async {
    // 1. Validate cơ bản
    if (phone.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập đầy đủ số điện thoại và mật khẩu';
      notifyListeners();
      return;
    }

    // 2. Bắt đầu loading, xóa lỗi cũ
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 3. Gọi API lấy Token
      await _authProvider.login(phone.trim(), password.trim());


      // 5. Thành công -> Kích hoạt callback để View chuyển trang
      onSuccess();
    } catch (e) {
      // 6. Thất bại -> Lưu lỗi lại
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      // 7. Tắt loading dù thành công hay thất bại
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm xóa lỗi (Dùng khi người dùng đã xem xong thông báo lỗi)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}