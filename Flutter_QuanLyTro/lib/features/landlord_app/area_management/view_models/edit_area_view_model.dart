import 'package:flutter/material.dart';
import '../../../../data/providers/area_provider.dart';

class EditAreaViewModel extends ChangeNotifier {
  final AreaProvider _areaProvider = AreaProvider();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> updateAreaInfo({
    required String areaId,
    required Map<String, dynamic> payload,
  }) async {
    if (payload['name'].toString().trim().isEmpty ||
        payload['address'].toString().trim().isEmpty) {
      _errorMessage = 'Tên và địa chỉ không được để trống.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _areaProvider.updateArea(areaId, payload);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}