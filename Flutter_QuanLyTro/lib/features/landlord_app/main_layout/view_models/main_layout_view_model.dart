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

  static const String _selectedAreaKey = 'SELECTED_AREA_ID';

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  List<AreaModel> _areas = [];
  List<AreaModel> get areas => _areas;

  AreaModel? _selectedArea;
  AreaModel? get selectedArea => _selectedArea;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
        debugPrint("FCM Token lấy được: $deviceToken");

        await _authProvider.saveFcmToken(deviceToken);
      }
    } catch (e) {
      debugPrint("Lỗi khi cấu hình FCM: $e");
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authProvider.logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedAreaKey);

    _currentUser = null;
    _selectedArea = null;
    _areas = [];
    _currentIndex = 0;

    _isLoading = false;
    notifyListeners();
  }

  void changeTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> changeArea(AreaModel newArea) async {
    if (_selectedArea?.id != newArea.id){
      _selectedArea = newArea;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedAreaKey, newArea.id);
    }
  }

  String? get selectedAreaId => _selectedArea?.id;

  Future<void> addAndSelectArea(AreaModel area) async {
    _isLoading = true;
    notifyListeners();

    _areas.add(area);
    _selectedArea = area;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAreaKey, area.id);

    try {
      if (_currentUser == null) {
        _currentUser = await _userProvider.getCurrentUser();
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin user sau onboarding: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}