import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/request/user_update_request.dart';
import '../../../../data/models/response/user_model.dart';
import '../../../../data/repository/user_repository.dart';

class TenantProfileViewModel extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();

  bool isFetching = true;
  bool isUpdatingProfile = false;
  bool isUpdatingPassword = false;
  String? errorMessage;

  UserModel? currentUser;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController hometownController = TextEditingController();
  final TextEditingController idCardController = TextEditingController();
  DateTime? selectedDob;

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  Future<void> fetchProfile() async {
    isFetching = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _userRepo.getCurrentUser();

      fullNameController.text = currentUser?.fullName ?? '';
      phoneController.text = currentUser?.phone ?? '';
      hometownController.text = currentUser?.hometown ?? '';
      idCardController.text = currentUser?.idCardNumber ?? '';

      if (currentUser?.dob != null && currentUser!.dob!.isNotEmpty) {
        selectedDob = DateTime.tryParse(currentUser!.dob!);
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isFetching = false;
      notifyListeners();
    }
  }


  Future<bool> changePassword() async {
    final oldPass = oldPasswordController.text;
    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty) {
      errorMessage = 'Vui lòng nhập đầy đủ mật khẩu cũ và mới.';
      notifyListeners();
      return false;
    }

    if (newPass != confirmPass) {
      errorMessage = 'Mật khẩu xác nhận không khớp!';
      notifyListeners();
      return false;
    }

    isUpdatingPassword = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _userRepo.changePassword(oldPass, newPass);
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isUpdatingPassword = false;
      notifyListeners();
    }
  }

  void updateDob(DateTime date) {
    selectedDob = date;
    notifyListeners();
  }

  String displayDate(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    hometownController.dispose();
    idCardController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}