import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/data/models/response/user_model.dart';
import 'package:flutter_quanlytro/data/repository/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/response/area_model.dart';
import '../../../../data/repository/area_repository.dart';

class MainLayoutViewModel extends ChangeNotifier {
  final AreaRepository _areaProvider = AreaRepository();
  final UserRepository _userProvider = UserRepository();

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
      // Lấy id đang chọn hiện tại
      String? targetAreaId = _selectedArea?.id;

      // Nếu là lần đầu mở app (targetAreaId chưa có), thử đọc ID đã lưu từ SharedPreferences
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
            // Kiểm tra xem ID đã lưu có thực sự tồn tại trong danh sách mới tải về không
            _selectedArea = _areas.firstWhere(
                  (a) => a.id == targetAreaId,
            );
          } catch (_) {
            // Nếu không tìm thấy (Khu trọ đã bị xóa ở thiết bị khác), fallback về khu đầu tiên
            _selectedArea = _areas.first;
          }
        } else {
          _selectedArea = selectLast ? _areas.last : _areas.first;
        }

        // Đồng bộ lại ID thực tế được chọn vào bộ nhớ
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_selectedAreaKey, _selectedArea!.id);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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