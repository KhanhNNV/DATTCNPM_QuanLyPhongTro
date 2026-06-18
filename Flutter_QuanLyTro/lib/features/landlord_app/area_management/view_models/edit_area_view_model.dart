import 'package:flutter/material.dart';
import '../../../../data/models/response/area_model.dart';
import '../../../../data/providers/area_provider.dart';


class EditAreaViewModel extends ChangeNotifier {
  final AreaProvider _areaProvider = AreaProvider();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- QUẢN LÝ TEXT CONTROLLERS VÀ BIẾN STATE ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  int _invoiceDay = 1;
  int get invoiceDay => _invoiceDay;

  int _dueDate = 5;
  int get dueDate => _dueDate;

  // --- HÀM KHỞI TẠO DỮ LIỆU ---
  void initData(AreaModel area) {
    nameController.text = area.name;
    addressController.text = area.address;
    _invoiceDay = area.invoiceDay;
    _dueDate = area.dueDate;
  }

  void updateInvoiceDay(int day) {
    _invoiceDay = day;
    notifyListeners();
  }

  void updateDueDate(int day) {
    _dueDate = day;
    notifyListeners();
  }

  // --- HÀM CALL API LƯU DỮ LIỆU ---
  Future<bool> updateAreaInfo(String areaId) async {
    if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
      _errorMessage = 'Tên và địa chỉ không được để trống.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final payload = {
      "name": nameController.text.trim(),
      "address": addressController.text.trim(),
      "invoiceDay": _invoiceDay,
      "dueDate": _dueDate,
    };

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

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }
}