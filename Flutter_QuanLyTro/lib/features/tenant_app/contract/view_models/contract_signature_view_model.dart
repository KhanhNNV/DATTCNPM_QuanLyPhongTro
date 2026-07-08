import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../../../../core/utils/contract_pdf_service.dart';
import '../../../../data/models/response/contract_detail_response.dart';
import '../../../../data/repository/area_repository.dart';
import '../../../../data/repository/contract_repository.dart';
import '../../../../data/repository/contract_template_repository.dart';

class ContractSignatureViewModel extends ChangeNotifier {
  final ContractRepository _contractRepo = ContractRepository();
  final ContractTemplateRepository _contractTemplateRepository = ContractTemplateRepository();
  final AreaRepository _areaRepo = AreaRepository();

  final String areaId;

  // Nhận nguyên Object để lấy thông tin kết xuất PDF
  final ContractDetailResponse currentContract;

  ContractSignatureViewModel({required this.currentContract,required this.areaId});

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 4,
    penColor: const Color(0xFF0D47A1),
    exportBackgroundColor: Colors.white,
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> submitSignature() async {
    if (signatureController.isEmpty) {
      _errorMessage = 'Vui lòng vẽ chữ ký của bạn trước khi xác nhận!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    File? tempFile;

    try {
      // 1. Xuất ảnh vẽ tay ra định dạng Bytes
      final Uint8List? imageBytes = await signatureController.toPngBytes();
      if (imageBytes == null) throw Exception('Không thể xuất dữ liệu chữ ký!');

      // 2. Tạo file PDF đã ký lưu tạm ở bộ nhớ máy (Tương tự logic update của Landlord)
      if (currentContract.templateId != null) {
        try {
          final templateDetail = await _contractTemplateRepository.getTemplateById(currentContract.templateId!);

          DateTime start = DateTime.parse(currentContract.startDate);
          DateTime end = DateTime.parse(currentContract.endDate);
          int durationMonths = (end.difference(start).inDays / 30).round();

          final areaDetail = await _areaRepo.getAreaById(areaId);
          int paymentDay = areaDetail.invoiceDay ?? 1;

          final pdfBytes = await ContractPdfService.generateContractPdf(
            templateName: templateDetail.name ?? "HỢP ĐỒNG THUÊ PHÒNG TRỌ",
            rentalContent: templateDetail.rentalContent ?? "",
            landlordDuty: templateDetail.landlordDuty ?? "",
            tenantDuty: templateDetail.tenantDuty ?? "",
            executionTerms: templateDetail.executionTerms ?? "",
            landlordName: currentContract.landlordName,
            landlordIdCard: currentContract.landlordIdCardNumber,
            landlordAddress: currentContract.landlordHometown,
            tenantName: currentContract.tenantName,
            tenantIdCard: currentContract.tenantIdCardNumber,
            tenantAddress: currentContract.tenantHometown,
            roomNumber: currentContract.roomNumber,
            roomAddress: currentContract.areaAddress,
            rentPrice: currentContract.rentPrice,
            depositAmount: currentContract.depositAmount,
            durationMonths: durationMonths,
            paymentDay: paymentDay,
            createdDate: currentContract.createdAt != null
                ? DateTime.tryParse(currentContract.createdAt!) ?? DateTime.now()
                : DateTime.now(),
            landlordSignatureUrl: currentContract.landlordSignatureUrl ?? "",
            tenantSignatureUrl: currentContract.tenantSignatureUrl ?? "",
            tenantSignatureBytes: imageBytes,
          );

          final tempDir = await getTemporaryDirectory();
          tempFile = File('${tempDir.path}/hop_dong_signed_${currentContract.id}.pdf');
          await tempFile.writeAsBytes(pdfBytes);
        } catch (pdfError) {
          _errorMessage = pdfError.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // 3. Đẩy dữ liệu lên Server xử lý
      await _contractRepo.signContract(
        contractId: currentContract.id,
        signatureBytes: imageBytes,
        pdfFile: tempFile,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      // Dọn dẹp file tạm tránh tràn bộ nhớ cache thiết bị
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSignature() => {signatureController.clear(), notifyListeners()};
  void clearError() => {_errorMessage = null, notifyListeners()};

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }
}