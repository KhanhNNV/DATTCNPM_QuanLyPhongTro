import 'package:flutter/material.dart';
import '../../../../data/repository/user_repository.dart';

class ForceChangePasswordViewModel extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  bool obscureOldPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  void toggleOldPasswordVisibility() {
    obscureOldPassword = !obscureOldPassword;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword = !obscureNewPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  Future<bool> changePassword() async {
    final oldPass = oldPasswordController.text;
    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      errorMessage = 'Vui lòng nhập đầy đủ thông tin.';
      notifyListeners();
      return false;
    }

    if (newPass != confirmPass) {
      errorMessage = 'Mật khẩu xác nhận không khớp!';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _userRepo.changePassword(oldPass, newPass);
      return true; // Đổi thành công
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}