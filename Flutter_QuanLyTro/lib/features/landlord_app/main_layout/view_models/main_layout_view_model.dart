import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/data/models/user_model.dart';
import 'package:flutter_quanlytro/data/providers/user_provider.dart';
import '../../../../data/models/area_model.dart';
import '../../../../data/providers/area_provider.dart';

class MainLayoutViewModel extends ChangeNotifier {
  final AreaProvider _areaProvider = AreaProvider();
  final UserProvider _userProvider = UserProvider();

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
      final results = await Future.wait([
        _areaProvider.getAreasByLandlord(),
        _userProvider.getCurrentUser(),
      ]);

      final listAreas = results[0] as List<AreaModel>;
      final user = results[1] as UserModel;

      _areas = listAreas;
      _currentUser = user;

      if (_areas.isNotEmpty) {
        _selectedArea = selectLast ? _areas.last : _areas.first;
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
    if (_selectedArea?.id != newArea.id){
      _selectedArea = newArea;
      notifyListeners();

      // TODO: Sau này bạn có thể bắn thêm event ở đây để báo cho HomePage tải lại danh sách phòng
    }
  }

  String? get selectedAreaId => _selectedArea?.id;

  void addAndSelectArea(AreaModel area) {
    _areas.add(area);

    _selectedArea = area;

    notifyListeners();
  }
}