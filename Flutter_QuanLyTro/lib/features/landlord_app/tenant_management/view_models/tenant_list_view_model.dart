import 'package:flutter/material.dart';
import '../../../../data/models/request/user_update_request.dart';
import '../../../../data/models/response/user_model.dart';
import '../../../../data/repository/user_repository.dart';

class TenantListViewModel extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  final String areaId;

  TenantListViewModel({required this.areaId});

  bool isLoading = true;
  String? errorMessage;
  List<UserModel> tenants = [];

  Future<void> fetchTenants() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      tenants = await _userRepo.getUsersByArea(areaId);
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTenant(String userId, UserUpdateRequest request) async {
    try {
      final updatedUser = await _userRepo.updateUser(userId, request);

      final index = tenants.indexWhere((t) => t.id == userId);
      if (index != -1) {
        tenants[index] = updatedUser;
        notifyListeners();
      }
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}