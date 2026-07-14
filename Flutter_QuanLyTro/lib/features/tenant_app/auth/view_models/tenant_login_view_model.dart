import 'package:flutter/material.dart';
import '../../../../data/repository/auth_repository.dart';
import '../../../../data/repository/user_repository.dart';

class TenantLoginViewModel extends ChangeNotifier {
  final AuthRepository _authProvider = AuthRepository();
  final UserRepository _userRepo = UserRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;


  String? _errorMessage;
  String? get errorMessage => _errorMessage;


  Future<void> login(String phone, String password, {required Function(bool isFirstLogin) onSuccess}) async {

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
        expectedRole: 'TENANT',
      );


      final currentUser = await _userRepo.getCurrentUser();
      final bool isFirst = currentUser.isFirstLogin ?? false;


      onSuccess(isFirst);

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