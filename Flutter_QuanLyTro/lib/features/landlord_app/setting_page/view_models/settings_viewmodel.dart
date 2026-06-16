import 'package:flutter/material.dart';

import '../../../../data/models/request/user_update_request.dart';
import '../../../../data/models/response/user_model.dart';
import '../../../../data/providers/user_provider.dart';


class SettingsViewModel extends ChangeNotifier {
  final UserProvider _userProvider = UserProvider();

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchCurrentUser() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _userProvider.getCurrentUser();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserInfo(UserUpdateRequest request) async {
    if (currentUser?.id == null) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _userProvider.updateUser(currentUser!.id.toString(), request);
      currentUser = updatedUser;
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

  void logout() {
    // // TODO: Xóa Token trong SharedPreferences hoặc SecureStorage tại đây
    // currentUser = null;
    // notifyListeners();
  }
}