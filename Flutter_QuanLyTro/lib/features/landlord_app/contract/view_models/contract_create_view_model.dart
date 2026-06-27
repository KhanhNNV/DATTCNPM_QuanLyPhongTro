import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/request/contract_create_request.dart';
import '../../../../data/models/request/contract_create_manual_request.dart';
import '../../../../data/models/response/contract_create_response.dart';
import '../../../../data/models/response/room_model.dart';
import '../../../../data/repository/contract_repository.dart';
import '../../../../data/repository/room_repository.dart';

class ContractCreateViewModel extends ChangeNotifier {
  final ContractRepository _contractRepo = ContractRepository();
  final RoomRepository _roomRepo = RoomRepository();
  final ImagePicker _picker = ImagePicker();

  // --- TRẠNG THÁI CHẾ ĐỘ ---
  bool _isOcrMode = true;
  bool get isOcrMode => _isOcrMode;

  void toggleMode(bool isOcr) {
    _isOcrMode = isOcr;
    notifyListeners();
  }

  // --- QUẢN LÝ PHÒNG ĐÃ CỌC & PHÒNG TRỐNG ---
  List<RoomModel> depositedRooms = [];
  RoomModel? selectedRoom;
  bool isFetchingRooms = false;

  // Gọi API lấy danh sách phòng DEPOSITED & AVAILABLE
  Future<void> loadDepositedRooms(String areaId) async {
    isFetchingRooms = true;
    notifyListeners();
    try {
      final allRooms = await _roomRepo.getRoomsByArea(areaId);
      depositedRooms = allRooms.where((room) {
        return room.status == 'DEPOSITED' || room.status == 'AVAILABLE';
      }).toList();
    } catch (e) {
      debugPrint('Lỗi tải phòng: $e');
    } finally {
      isFetchingRooms = false;
      notifyListeners();
    }
  }

  // Khi người dùng chọn phòng từ Dropdown
  void selectRoom(RoomModel? room) {
    selectedRoom = room;
    if (room != null) {
      depositAmountController.text = room.depositAmount.toInt().toString();
    } else {
      depositAmountController.clear();
    }
    notifyListeners();
  }

  // --- QUẢN LÝ FORM STATE & CONTROLLERS ---
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final depositAmountController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  // --- CHO CHẾ ĐỘ OCR ---
  File? _frontImage;
  File? get frontImage => _frontImage;
  File? _backImage;
  File? get backImage => _backImage;

  // --- CHO CHẾ ĐỘ THỦ CÔNG ---
  final tenantNameController = TextEditingController();
  final tenantHometownController = TextEditingController();
  final tenantIdCardNumberController = TextEditingController();
  DateTime? tenantDob;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void changeStartDate(DateTime date) { startDate = date; notifyListeners(); }
  void changeEndDate(DateTime date) { endDate = date; notifyListeners(); }
  void changeTenantDob(DateTime date) { tenantDob = date; notifyListeners(); }

  Future<void> pickImage({required bool isFront, bool fromCamera = false}) async {
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (pickedFile != null) {
      if (isFront) _frontImage = File(pickedFile.path);
      else _backImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  void removeImage({required bool isFront}) {
    if (isFront) _frontImage = null;
    else _backImage = null;
    notifyListeners();
  }

  Future<ContractCreateResponse?> submitContract() async {
    if (!formKey.currentState!.validate()) return null;

    if (selectedRoom == null) {
      throw Exception('Vui lòng chọn phòng để tạo hợp đồng!');
    }

    if (startDate == null || endDate == null) {
      throw Exception('Vui lòng chọn đầy đủ ngày bắt đầu và kết thúc!');
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (_isOcrMode) {
        if (_frontImage == null || _backImage == null) {
          throw Exception("Vui lòng chụp/chọn đầy đủ 2 mặt CCCD!");
        }

        final request = ContractCreateRequest(
          roomId: selectedRoom!.id,
          tenantPhone: phoneController.text.trim(),
          startDate: DateFormat('yyyy-MM-dd').format(startDate!),
          endDate: DateFormat('yyyy-MM-dd').format(endDate!),
          depositAmount: double.tryParse(depositAmountController.text.trim()) ?? 0.0,
        );

        return await _contractRepo.createContractOcr(
          dataRequest: request,
          frontImage: _frontImage!,
          backImage: _backImage!,
        );
      } else {
        if (tenantDob == null) {
          throw Exception('Vui lòng chọn ngày sinh của khách thuê!');
        }

        final request = ContractCreateManualRequest(
          roomId: selectedRoom!.id,
          startDate: DateFormat('yyyy-MM-dd').format(startDate!),
          endDate: DateFormat('yyyy-MM-dd').format(endDate!),
          depositAmount: double.tryParse(depositAmountController.text.trim()) ?? 0.0,
          tenantName: tenantNameController.text.trim(),
          tenantPhone: phoneController.text.trim(),
          tenantDob: DateFormat('yyyy-MM-dd').format(tenantDob!),
          tenantHometown: tenantHometownController.text.trim(),
          tenantIdCardNumber: tenantIdCardNumberController.text.trim(),
        );

        return await _contractRepo.createContractManual(request);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    depositAmountController.dispose();
    tenantNameController.dispose();
    tenantHometownController.dispose();
    tenantIdCardNumberController.dispose();
    super.dispose();
  }
}