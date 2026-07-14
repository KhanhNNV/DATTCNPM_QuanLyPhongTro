import 'package:flutter/material.dart';

import '../../../../core/services/fcm_service.dart';
import '../../../../data/models/response/contract_detail_response.dart';
import '../../../../data/models/response/user_model.dart';
import '../../../../data/repository/auth_repository.dart';
import '../../../../data/repository/contract_repository.dart';
import '../../../../data/repository/user_repository.dart';

class TenantMainLayoutViewModel extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  final ContractRepository _contractRepo = ContractRepository();
  final AuthRepository _authRepo = AuthRepository();


  int _currentIndex = 0;
  int get currentIndex => _currentIndex;


  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  ContractDetailResponse? _currentContract;
  ContractDetailResponse? get currentContract => _currentContract;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;


  Future<void> fetchInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _userRepo.getCurrentUser();

      _currentContract = await _contractRepo.getMyCurrentContract();

      await _setupFCM();

    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setupFCM() async {
    try {
      final fcmService = FCMService();

      await fcmService.initFCM();

      String? deviceToken = await fcmService.getDeviceToken();

      if (deviceToken != null && _currentUser != null) {
        debugPrint("🔵 FCM Token Khách thuê lấy được: $deviceToken");

        await _authRepo.saveFcmToken(deviceToken);
        debugPrint("🔵 Đã gọi api lưu token");
      }
    } catch (e) {
      debugPrint("Lỗi khi cấu hình FCM Khách thuê: $e");
    }
  }

  void changeTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  String? get currentRoomId => _currentContract?.roomId;

  String get displayRoomNumber => _currentContract?.roomNumber ?? "...";
  String get displayAreaName => _currentContract?.areaName ?? "...";
  String get displayTenantName => _currentUser?.fullName ?? "Khách thuê";
  String get displayTenantPhone => _currentUser?.phone ?? "---";


  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authRepo.logout();

    _currentUser = null;
    _currentContract = null;
    _currentIndex = 0;

    _isLoading = false;
    notifyListeners();
  }
}