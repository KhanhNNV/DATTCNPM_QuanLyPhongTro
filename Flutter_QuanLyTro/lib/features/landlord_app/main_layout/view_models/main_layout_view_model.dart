import 'package:flutter/material.dart';
import '../../../../data/models/area_model.dart';
import '../../../../data/providers/area_provider.dart';

class MainLayoutViewModel extends ChangeNotifier {
  final AreaProvider _areaProvider = AreaProvider();

  // --- QUẢN LÝ TAB ---
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // --- QUẢN LÝ DỮ LIỆU KHU TRỌ ---
  List<AreaModel> _areas = [];
  List<AreaModel> get areas => _areas;

  AreaModel? _selectedArea;
  AreaModel? get selectedArea => _selectedArea;

  // --- QUẢN LÝ TRẠNG THÁI LOADING / LỖI ---
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- CÁC HÀM XỬ LÝ ---

  // Gọi API lấy danh sách khu trọ
  Future<void> fetchAreas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _areaProvider.getAreasByLandlord();
      _areas = list;

      // Nếu có dữ liệu, mặc định chọn khu trọ đầu tiên
      if (_areas.isNotEmpty) {
        _selectedArea = _areas.first;
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

  // Đổi khu trọ đang được chọn
  void changeArea(AreaModel newArea) {
    if (_selectedArea?.name != newArea.name) {
      _selectedArea = newArea;
      notifyListeners();

      // TODO: Sau này bạn có thể bắn thêm event ở đây để báo cho HomePage tải lại danh sách phòng
    }
  }
}