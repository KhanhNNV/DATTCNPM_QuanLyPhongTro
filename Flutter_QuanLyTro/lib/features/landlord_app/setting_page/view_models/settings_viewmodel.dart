import 'package:flutter/material.dart';
import '../../../../data/models/request/user_update_request.dart';
import '../../../../data/models/request/bank_info_update_request.dart';
import '../../../../data/models/response/user_model.dart';
import '../../../../data/repository/user_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final UserRepository _userProvider = UserRepository();


  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final hometownController = TextEditingController();
  DateTime? selectedDob;

  final bankIdController = TextEditingController();
  final accountNoController = TextEditingController();
  final accountNameController = TextEditingController();

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchCurrentUser() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _userProvider.getCurrentUser();

      if (currentUser != null) {

        fullNameController.text = currentUser!.fullName ?? '';
        phoneController.text = currentUser!.phone ?? '';
        hometownController.text = currentUser!.hometown ?? '';

        if (currentUser!.dob != null && currentUser!.dob!.isNotEmpty) {
          selectedDob = DateTime.tryParse(currentUser!.dob!);
        }


        bankIdController.text = currentUser!.bankId ?? '';
        accountNoController.text = currentUser!.accountNo ?? '';
        accountNameController.text = currentUser!.accountName ?? '';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateDob(DateTime date) {
    selectedDob = date;
    notifyListeners();
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String displayDate(DateTime? date) {
    if (date == null) return 'Chọn ngày sinh';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<bool> updateUserInfo() async {
    if (currentUser?.id == null) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final request = UserUpdateRequest(
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
        hometown: hometownController.text.trim(),
        dob: formatDate(selectedDob),
      );

      final updatedUser = await _userProvider.updateUser(currentUser!.id.toString(), request);
      currentUser = updatedUser;

      passwordController.clear();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> updateBankInfo() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final request = BankInfoUpdateRequest(
        bankId: bankIdController.text.trim(),
        accountNo: accountNoController.text.trim(),
        accountName: accountNameController.text.trim(),
      );

      await _userProvider.updateBankInfo(request);


      await fetchCurrentUser();

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {}

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    hometownController.dispose();
    bankIdController.dispose();
    accountNoController.dispose();
    accountNameController.dispose();
    super.dispose();
  }
}