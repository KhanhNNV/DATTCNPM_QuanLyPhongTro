import 'package:flutter/material.dart';
import '../../../../data/repository/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authProvider = AuthRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required String idCardNumber,
    required String hometown,
    required VoidCallback onSuccess,
  }) async {
    // Kiểm tra rỗng cho tất cả các trường
    if (fullName.trim().isEmpty ||
        phone.trim().isEmpty ||
        password.trim().isEmpty ||
        idCardNumber.trim().isEmpty ||
        hometown.trim().isEmpty) {
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
      await _authProvider.register(
          fullName.trim(),
          phone.trim(),
          password.trim(),
          idCardNumber.trim(),
          hometown.trim()
      );

      await _authProvider.login(
        phone.trim(),
        password.trim(),
        expectedRole: 'LANDLORD',
      );
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