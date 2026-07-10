import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/data/models/response/user_model.dart';
import 'package:flutter_quanlytro/data/repository/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../data/models/response/area_model.dart';
import '../../../../data/repository/area_repository.dart';
import '../../../../data/repository/auth_repository.dart';

class MainLayoutViewModel extends ChangeNotifier {
  final AreaRepository _areaProvider = AreaRepository();
  final UserRepository _userProvider = UserRepository();
  final AuthRepository _authProvider = AuthRepository();

  // Key dùng để lưu và đọc ID khu trọ dưới bộ nhớ máy
  static const String _selectedAreaKey = 'SELECTED_AREA_ID';

  // --- QUẢN LÝ TAB ---
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // --- QUẢN LÝ DỮ LIỆU KHU TRỌ ---
  List<AreaModel> _areas = [];
  List<AreaModel> get areas => _areas;

  AreaModel? _selectedArea;
  AreaModel? get selectedArea => _selectedArea;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // --- QUẢN LÝ TRẠNG THÁI LOADING / LỖI ---
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- CÁC HÀM XỬ LÝ ---

  Future<void> fetchInitialData({bool selectLast = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? targetAreaId = _selectedArea?.id;
      if (targetAreaId == null) {
        final prefs = await SharedPreferences.getInstance();
        targetAreaId = prefs.getString(_selectedAreaKey);
      }

      final results = await Future.wait([
        _areaProvider.getAreasByLandlord(),
        _userProvider.getCurrentUser(),
      ]);

      final listAreas = results[0] as List<AreaModel>;
      final user = results[1] as UserModel;

      _areas = listAreas;
      _currentUser = user;

      if (_areas.isNotEmpty) {
        if (targetAreaId != null) {
          try {
            _selectedArea = _areas.firstWhere((a) => a.id == targetAreaId);
          } catch (_) {
            _selectedArea = _areas.first;
          }
        } else {
          _selectedArea = selectLast ? _areas.last : _areas.first;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_selectedAreaKey, _selectedArea!.id);
      }

      // ==========================================
      // 🚀 1. GỌI KHỞI TẠO FCM TẠI ĐÂY
      // Xảy ra ngay sau khi đã có thông tin _currentUser
      // ==========================================
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

      // Khởi tạo các cấu hình (xin quyền, lắng nghe sự kiện)
      await fcmService.initFCM();

      // Lấy Token của thiết bị hiện tại
      String? deviceToken = await fcmService.getDeviceToken();

      if (deviceToken != null && _currentUser != null) {
        debugPrint("FCM Token lấy được: $deviceToken");

        // Gọi API gửi deviceToken lên Backend
        await _authProvider.saveFcmToken(deviceToken);
      }
    } catch (e) {
      debugPrint("Lỗi khi cấu hình FCM: $e");
    }
  }


  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Gọi API xóa token phía Backend + Xóa Local Storage
    await _authProvider.logout();

    // Xóa bộ nhớ lưu ID Khu trọ
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedAreaKey);

    // Reset lại toàn bộ dữ liệu trên RAM
    _currentUser = null;
    _selectedArea = null;
    _areas = [];
    _currentIndex = 0;

    _isLoading = false;
    notifyListeners();
  }

  // Chuyển Tab BottomBar
  void changeTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Đổi khu trọ đang được chọn (Chuyển sang hàm async để lưu dữ liệu)
  Future<void> changeArea(AreaModel newArea) async {
    if (_selectedArea?.id != newArea.id){
      _selectedArea = newArea;
      notifyListeners();

      // Lưu ID mới vào bộ nhớ khi người dùng bấm chọn
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedAreaKey, newArea.id);

      // TODO: Sau này bạn có thể bắn thêm event ở đây để báo cho HomePage tải lại danh sách phòng
    }
  }

  String? get selectedAreaId => _selectedArea?.id;

  // Cập nhật hàm để tự ghi nhớ khi tạo mới khu trọ thành công
  Future<void> addAndSelectArea(AreaModel area) async {
    _areas.add(area);
    _selectedArea = area;
    notifyListeners();

    // Lưu ID của khu trọ vừa tạo mới
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAreaKey, area.id);
  }
}