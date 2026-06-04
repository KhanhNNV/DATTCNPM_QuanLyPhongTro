import 'package:flutter/material.dart';
import '../../../../data/models/area_model.dart';
import '../../../../data/providers/area_provider.dart';

class OnboardingViewModel extends ChangeNotifier {
  final AreaProvider _areaProvider = AreaProvider();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> submitOnboarding({
    required Map<String, dynamic> payload,
    required Function(AreaModel area) onSuccess,
  }) async {
    if (payload['name'].toString().trim().isEmpty ||
        payload['address'].toString().trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên và địa chỉ khu trọ.';
      notifyListeners();
      return;
    }

    if (payload['defaultRentPrice'] == 0) {
      _errorMessage = 'Vui lòng nhập giá phòng mặc định.';
      notifyListeners();
      return;
    }

    List<int> floors = payload['roomsPerFloor'];
    if (floors.isEmpty || floors.every((count) => count == 0)) {
      _errorMessage = 'Vui lòng cấu hình ít nhất 1 phòng cho khu trọ.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final AreaModel newArea = await _areaProvider.onboardNewLandlord(payload);

      onSuccess(newArea);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateArea({
    required String areaId,
    required Map<String, dynamic> payload,
  }) async {
    await _areaProvider.updateArea(areaId, payload);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}