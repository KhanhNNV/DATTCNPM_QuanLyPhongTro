import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/request/contract_create_request.dart';
import '../../../../data/models/response/contract_create_response.dart';
import '../../../../data/repository/contract_repository.dart';


class ContractCreateViewModel extends ChangeNotifier {
  final ContractRepository _repository = ContractRepository();
  final ImagePicker _picker = ImagePicker();

  // --- QUẢN LÝ FORM STATE & CONTROLLERS ---
  final formKey = GlobalKey<FormState>();
  final roomIdController = TextEditingController();
  final templateIdController = TextEditingController();
  final phoneController = TextEditingController();
  final depositAmountController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  File? _frontImage;
  File? get frontImage => _frontImage;

  File? _backImage;
  File? get backImage => _backImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Thay đổi ngày bắt đầu
  void changeStartDate(DateTime date) {
    startDate = date;
    notifyListeners();
  }

  // Thay đổi ngày kết thúc
  void changeEndDate(DateTime date) {
    endDate = date;
    notifyListeners();
  }

  // Chọn ảnh từ Thư viện hoặc Camera
  Future<void> pickImage({required bool isFront, bool fromCamera = false}) async {
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;

    // Đã thêm maxWidth, maxHeight để tự động resize và giảm dung lượng file
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Giảm chất lượng xuống 70%
      maxWidth: 1920,   // Giới hạn chiều rộng tối đa (Full HD)
      maxHeight: 1920,  // Giới hạn chiều cao tối đa
    );

    if (pickedFile != null) {
      if (isFront) {
        _frontImage = File(pickedFile.path);
      } else {
        _backImage = File(pickedFile.path);
      }
      notifyListeners();
    }
  }

  void removeImage({required bool isFront}) {
    if (isFront) {
      _frontImage = null;
    } else {
      _backImage = null;
    }
    notifyListeners();
  }

  // Logic Submit Form gom hết vào đây
  Future<ContractCreateResponse?> submitContract() async {
    // 1. Validate Form text fields
    if (!formKey.currentState!.validate()) return null;

    // 2. Validate ngày tháng
    if (startDate == null || endDate == null) {
      throw Exception('Vui lòng chọn đầy đủ ngày bắt đầu và kết thúc!');
    }

    // 3. Validate ảnh CCCD
    if (_frontImage == null || _backImage == null) {
      throw Exception("Vui lòng chụp/chọn đầy đủ 2 mặt CCCD!");
    }

    _isLoading = true;
    notifyListeners();

    try {
      final request = ContractCreateRequest(
        roomId: roomIdController.text.trim(),
        templateId: templateIdController.text.trim(),
        tenantPhone: phoneController.text.trim(),
        startDate: DateFormat('yyyy-MM-dd').format(startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(endDate!),
        depositAmount:
        double.tryParse(depositAmountController.text.trim()) ?? 0.0,
      );

      final response = await _repository.createContractOcr(
        dataRequest: request,
        frontImage: _frontImage!,
        backImage: _backImage!,
      );

      return response;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ của các Controller khi ViewModel bị hủy
    roomIdController.dispose();
    templateIdController.dispose();
    phoneController.dispose();
    depositAmountController.dispose();
    super.dispose();
  }
}