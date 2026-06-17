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

  // --- QUẢN LÝ TEXT CONTROLLERS CHO FORM PHÒNG ---
  final floorController = TextEditingController();
  final numberController = TextEditingController();
  final sizeController = TextEditingController();
  final priceController = TextEditingController();
  final depositController = TextEditingController();
  final maxController = TextEditingController();

  // --- QUẢN LÝ TEXT CONTROLLERS CHO DỊCH VỤ ---
  // Dùng Map để lưu controller theo ID dịch vụ, tránh mất chữ khi cuộn ListView
  final Map<String, TextEditingController> servicePriceControllers = {};

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- HELPER DỌN/ĐIỀN FORM ---
  void resetRoomForm() {
    floorController.text = '1';
    numberController.clear();
    sizeController.clear();
    priceController.clear();
    depositController.clear();
    maxController.text = '4';
  }

  void fillRoomForm(dynamic room) {
    floorController.text = room['floor'].toString();
    numberController.text = room['roomNumber'];
    sizeController.text = room['areaSize'].toString().replaceAll(RegExp(r'\.0$'), '');
    priceController.text = room['rentPrice'].toString().replaceAll(RegExp(r'\.0$'), '');
    depositController.text = room['depositAmount'].toString().replaceAll(RegExp(r'\.0$'), '');
    maxController.text = room['maxOccupants'].toString();
  }

  Future<void> loadAreaDetails(String areaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _services = await _provider.getServicesByArea(areaId);
      _rooms = await _provider.getRoomsByArea(areaId);
      _rooms.sort((a, b) => (a['roomNumber'] ?? '').compareTo(b['roomNumber'] ?? ''));

      // Khởi tạo giá trị mặc định cho các controller Dịch vụ
      for (var service in _services) {
        final id = service['id'].toString();
        if (!servicePriceControllers.containsKey(id)) {
          final priceStr = service['price'].toString().replaceAll(RegExp(r'\.0$'), '');
          servicePriceControllers[id] = TextEditingController(text: priceStr);
        }
      }
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

  @override
  void dispose() {
    floorController.dispose();
    numberController.dispose();
    sizeController.dispose();
    priceController.dispose();
    depositController.dispose();
    maxController.dispose();
    for (var controller in servicePriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}