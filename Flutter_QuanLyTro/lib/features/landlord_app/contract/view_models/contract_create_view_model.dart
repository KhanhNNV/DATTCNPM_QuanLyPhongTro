import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/data/repository/area_repository.dart';
import 'package:flutter_quanlytro/data/repository/contract_template_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/contract_pdf_service.dart';
import '../../../../data/models/request/contract_create_request.dart';
import '../../../../data/models/request/contract_create_manual_request.dart';
import '../../../../data/models/response/contract_create_response.dart';
import '../../../../data/models/response/room_model.dart';
import '../../../../data/repository/contract_repository.dart';
import '../../../../data/repository/room_repository.dart';

class ContractCreateViewModel extends ChangeNotifier {
  final ContractRepository _contractRepo = ContractRepository();
  final ContractTemplateRepository _contractTemplateRepository = ContractTemplateRepository();
  final AreaRepository _areaRepo = AreaRepository();
  final RoomRepository _roomRepo = RoomRepository();
  final ImagePicker _picker = ImagePicker();

  String? _currentAreaId;

  bool _isOcrMode = true;
  bool get isOcrMode => _isOcrMode;

  void toggleMode(bool isOcr) {
    _isOcrMode = isOcr;
    notifyListeners();
  }

  List<RoomModel> depositedRooms = [];
  RoomModel? selectedRoom;
  bool isFetchingRooms = false;

  Future<void> loadDepositedRooms(String areaId) async {
    _currentAreaId = areaId;
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

  void selectRoom(RoomModel? room) {
    selectedRoom = room;
    if (room != null) {
      depositAmountController.text = room.depositAmount.toInt().toString();
    } else {
      depositAmountController.clear();
    }
    notifyListeners();
  }

  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final depositAmountController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  File? _frontImage;
  File? get frontImage => _frontImage;
  File? _backImage;
  File? get backImage => _backImage;

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
      ContractCreateResponse contractResponse;

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

        contractResponse = await _contractRepo.createContractOcr(
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

        contractResponse = await _contractRepo.createContractManual(request);
      }


      try {
        final contractId = contractResponse.contractId;

        final contractDetail = await _contractRepo.getContractDetail(contractId);

        if (contractDetail.templateId == null) {
          throw Exception("Hợp đồng không có mã Mẫu (Template ID)!");
        }

        final templateDetail = await _contractTemplateRepository.getTemplateById(contractDetail.templateId!);

        final areaDetail = await _areaRepo.getAreaById(_currentAreaId!);

        int durationMonths = 0;
        if (startDate != null && endDate != null) {
          durationMonths = (endDate!.difference(startDate!).inDays / 30).round();
        }

        int paymentDay = areaDetail.invoiceDay ?? 1;

        final pdfBytes = await ContractPdfService.generateContractPdf(
          templateName: templateDetail.name ?? "HỢP ĐỒNG THUÊ PHÒNG TRỌ",
          rentalContent: templateDetail.rentalContent ?? "",
          landlordDuty: templateDetail.landlordDuty ?? "",
          tenantDuty: templateDetail.tenantDuty ?? "",
          executionTerms: templateDetail.executionTerms ?? "",

          // Dữ liệu User
          landlordName: contractDetail.landlordName,
          landlordIdCard: contractDetail.landlordIdCardNumber,
          landlordAddress: contractDetail.landlordHometown,

          tenantName: contractDetail.tenantName,
          tenantIdCard: contractDetail.tenantIdCardNumber,
          tenantAddress: contractDetail.tenantHometown,

          roomNumber: contractDetail.roomNumber,
          roomAddress: areaDetail.address,
          rentPrice: contractDetail.rentPrice,
          depositAmount: contractDetail.depositAmount,
          durationMonths: durationMonths,
          paymentDay: paymentDay,
          startDate: contractDetail.startDate,
          endDate: contractDetail.endDate,

          createdDate: contractDetail.createdAt != null
              ? DateTime.tryParse(contractDetail.createdAt!) ?? DateTime.now()
              : DateTime.now(),
          landlordSignatureUrl: contractDetail.landlordSignatureUrl ?? "",
        );


        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/hop_dong_$contractId.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await _contractRepo.uploadContractFile(contractId, tempFile);

        if (await tempFile.exists()) {
          await tempFile.delete();
        }

      } catch (e) {
      }

      return contractResponse;

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