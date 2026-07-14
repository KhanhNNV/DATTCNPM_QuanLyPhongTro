import 'package:flutter/material.dart';
import '../../../../data/repository/auth_repository.dart';
import '../../../../data/repository/user_repository.dart';
import '../../../../data/models/response/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authProvider = AuthRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;


  Future<void> login(String phone, String password, {required VoidCallback onSuccess}) async {

    if (phone.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập đầy đủ số điện thoại và mật khẩu';
      notifyListeners();
      return;
    }


    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {

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