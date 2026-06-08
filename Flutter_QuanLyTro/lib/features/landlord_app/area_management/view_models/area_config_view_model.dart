import 'package:flutter/material.dart';
import '../../../../data/providers/area_config_provider.dart';

class AreaConfigViewModel extends ChangeNotifier {
  final AreaConfigProvider _provider = AreaConfigProvider();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _services = [];
  List<dynamic> get services => _services;

  List<dynamic> _rooms = [];
  List<dynamic> get rooms => _rooms;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadAreaDetails(String areaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _services = await _provider.getServicesByArea(areaId);
      _rooms = await _provider.getRoomsByArea(areaId);
      _rooms.sort((a, b) => (a['roomNumber'] ?? '').compareTo(b['roomNumber'] ?? ''));
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveService(String areaId, String? serviceId, Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (serviceId == null) {
        await _provider.createService(areaId, payload);
      } else {
        await _provider.updateService(serviceId, payload);
      }
      await loadAreaDetails(areaId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xử lý tạo hoặc cập nhật phòng lẻ
  Future<bool> saveRoom(String areaId, String? roomId, Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (roomId == null) {
        await _provider.createRoom(payload);
      } else {
        await _provider.updateRoom(roomId, payload);
      }
      await loadAreaDetails(areaId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa phòng
  Future<bool> deleteRoom(String areaId, String roomId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _provider.deleteRoom(roomId);
      await loadAreaDetails(areaId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}