import 'package:flutter/material.dart';
import '../../../../data/models/response/area_model.dart';
import '../../../../data/repository/area_repository.dart';
import '../models/onboarding_models.dart';

class OnboardingViewModel extends ChangeNotifier {
  final AreaRepository _areaProvider = AreaRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- 1. STATE THÔNG TIN KHU TRỌ ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  int invoiceDay = 1;
  int dueDate = 5;

  // --- 2. STATE PHÒNG MẪU ---
  final TextEditingController areaSizeController = TextEditingController();
  final TextEditingController rentPriceController = TextEditingController();
  final TextEditingController depositController = TextEditingController();
  final TextEditingController maxOccupantsController = TextEditingController();

  // --- 3. STATE DỊCH VỤ ---
  final List<AppServiceItem> services = [
    AppServiceItem(name: 'Điện', calcType: ServiceCalculationType.byIndex),
    AppServiceItem(name: 'Nước', calcType: ServiceCalculationType.byIndex),
    AppServiceItem(name: 'Rác', calcType: ServiceCalculationType.perPerson),
    AppServiceItem(name: 'Wifi', calcType: ServiceCalculationType.perRoom),
  ];

  // --- 4. STATE TẦNG ĐỘNG ---
  final TextEditingController floorCountController = TextEditingController();
  int floorCount = 0;
  final List<TextEditingController> roomsPerFloorControllers = [];

  // --- CÁC HÀM CẬP NHẬT TRẠNG THÁI ---
  void updateInvoiceDay(int day) {
    invoiceDay = day;
    notifyListeners();
  }

  void updateDueDate(int day) {
    dueDate = day;
    notifyListeners();
  }

  void updateServiceType() {
    notifyListeners();
  }

  void updateFloorCount(String value) {
    int? newCount = int.tryParse(value);
    if (newCount == null || newCount < 0) newCount = 0;
    if (newCount > 50) newCount = 50;

    floorCount = newCount;

    if (roomsPerFloorControllers.length < floorCount) {
      for (int i = roomsPerFloorControllers.length; i < floorCount; i++) {
        roomsPerFloorControllers.add(TextEditingController(text: '10'));
      }
    } else if (roomsPerFloorControllers.length > floorCount) {
      for (int i = roomsPerFloorControllers.length - 1; i >= floorCount; i--) {
        roomsPerFloorControllers[i].dispose();
        roomsPerFloorControllers.removeAt(i);
      }
    }
    notifyListeners();
  }

  // --- HÀM XỬ LÝ GỬI DỮ LIỆU ---
  // Trả về AreaModel nếu thành công, null nếu thất bại để UI tự điều hướng
  Future<AreaModel?> submitOnboarding() async {
    if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên và địa chỉ khu trọ.';
      notifyListeners();
      return null;
    }

    final defaultRentPrice = double.tryParse(rentPriceController.text) ?? 0.0;
    if (defaultRentPrice == 0) {
      _errorMessage = 'Vui lòng nhập giá phòng mặc định.';
      notifyListeners();
      return null;
    }

    List<int> floors = roomsPerFloorControllers
        .map((controller) => int.tryParse(controller.text) ?? 0)
        .toList();

    if (floors.isEmpty || floors.every((count) => count == 0)) {
      _errorMessage = 'Vui lòng cấu hình ít nhất 1 phòng cho khu trọ.';
      notifyListeners();
      return null;
    }

    List<Map<String, dynamic>> servicesPayload = services.map((s) {
      return {
        'name': s.name,
        'calcType': s.calcType.backendValue,
        'price': num.tryParse(s.priceController.text) ?? 0,
      };
    }).toList();

    final payload = {
      "name": nameController.text.trim(),
      "address": addressController.text.trim(),
      "invoiceDay": invoiceDay,
      "dueDate": dueDate,
      "services": servicesPayload,
      "roomsPerFloor": floors,
      "defaultAreaSize": double.tryParse(areaSizeController.text) ?? 0.0,
      "defaultRentPrice": defaultRentPrice,
      "defaultDepositAmount": double.tryParse(depositController.text) ?? 0.0,
      "defaultMaxOccupants": int.tryParse(maxOccupantsController.text) ?? 1,
    };

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final AreaModel newArea = await _areaProvider.onboardNewLandlord(payload);
      return newArea;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
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
    areaSizeController.dispose();
    rentPriceController.dispose();
    depositController.dispose();
    maxOccupantsController.dispose();
    floorCountController.dispose();
    for (var controller in roomsPerFloorControllers) {
      controller.dispose();
    }
    for (var service in services) {
      service.priceController.dispose();
    }
    super.dispose();
  }
}