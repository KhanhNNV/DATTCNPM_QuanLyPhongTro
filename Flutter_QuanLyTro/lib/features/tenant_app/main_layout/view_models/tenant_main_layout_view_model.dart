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

  // --- QUẢN LÝ TAB ---
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // --- THÔNG TIN DỮ LIỆU ---
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  ContractDetailResponse? _currentContract;
  ContractDetailResponse? get currentContract => _currentContract;

  // --- TRẠNG THÁI ---
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- CÁC HÀM XỬ LÝ ---

  Future<void> fetchInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Lấy thông tin User hiện tại
      _currentUser = await _userRepo.getCurrentUser();

      // Lấy thông tin Hợp đồng của khách thuê
      _currentContract = await _contractRepo.getMyCurrentContract();

      // ==========================================
      // 🚀 GỌI KHỞI TẠO FCM SAU KHI LẤY ĐƯỢC USER
      // ==========================================
      await _setupFCM();

    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cấu hình FCM và lưu Token lên Backend
  Future<void> _setupFCM() async {
    try {
      final fcmService = FCMService();

      // Khởi tạo các cấu hình (xin quyền, lắng nghe sự kiện)
      await fcmService.initFCM();

      // Lấy Token của thiết bị hiện tại
      String? deviceToken = await fcmService.getDeviceToken();

      if (deviceToken != null && _currentUser != null) {
        debugPrint("🔵 FCM Token Khách thuê lấy được: $deviceToken");

        // Gọi API gửi deviceToken lên Backend
        await _authRepo.saveFcmToken(deviceToken);
        debugPrint("🔵 Đã gọi api lưu token");
      }
    } catch (e) {
      debugPrint("Lỗi khi cấu hình FCM Khách thuê: $e");
    }
  }

  // Chuyển Tab BottomBar
  void changeTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  String? get currentRoomId => _currentContract?.roomId;

  // Lấy các text hiển thị nhanh trên UI
  String get displayRoomNumber => _currentContract?.roomNumber ?? "...";
  String get displayAreaName => _currentContract?.areaName ?? "...";
  String get displayTenantName => _currentUser?.fullName ?? "Khách thuê";
  String get displayTenantPhone => _currentUser?.phone ?? "---";

  // Hàm Đăng xuất
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Gọi API xóa token phía Backend + Xóa Local Storage
    await _authRepo.logout();

    _currentUser = null;
    _currentContract = null;
    _currentIndex = 0;

    _isLoading = false;
    notifyListeners();
  }
}