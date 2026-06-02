import 'package:flutter/material.dart';
import '../../../../data/providers/auth_provider.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthProvider _authProvider = AuthProvider();

  // Trạng thái Loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Trạng thái Lỗi
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Hàm xử lý đăng ký
  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required VoidCallback onSuccess,
  }) async {
    if (fullName.trim().isEmpty || phone.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập đầy đủ thông tin.';
      notifyListeners();
      return;
    }

    if (password.trim().length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authProvider.register(fullName.trim(), phone.trim(), password.trim());
      await _authProvider.login(phone.trim(), password.trim());
      onSuccess();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}