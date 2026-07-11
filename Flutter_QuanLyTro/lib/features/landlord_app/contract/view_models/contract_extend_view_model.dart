import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/contract_pdf_service.dart';
import '../../../../data/models/request/contract_extend_request.dart';
import '../../../../data/models/response/contract_detail_response.dart';
import '../../../../data/repository/area_repository.dart';
import '../../../../data/repository/contract_repository.dart';
import '../../../../data/repository/contract_template_repository.dart';

class ContractExtendViewModel extends ChangeNotifier {
  final ContractRepository _contractRepo = ContractRepository();
  final ContractTemplateRepository _contractTemplateRepo = ContractTemplateRepository();
  final AreaRepository _areaRepo = AreaRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? newEndDate;

  void changeNewEndDate(DateTime date) {
    newEndDate = date;
    notifyListeners();
  }

  Future<bool> submitExtendContract({
    required String oldContractId,
    required String currentAreaId,
  }) async {
    if (newEndDate == null) {
      _errorMessage = "Vui lòng chọn ngày kết thúc mới!";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String endDateStr = DateFormat('yyyy-MM-dd').format(newEndDate!);
      final request = ContractExtendRequest(newEndDate: endDateStr);

      final ContractDetailResponse newContractDetail = await _contractRepo.extendContract(
        oldContractId,
        request,
      );

      final newContractId = newContractDetail.id;

      if (newContractDetail.templateId == null) {
        throw Exception("Hợp đồng mới không có mã Mẫu (Template ID) để tạo PDF!");
      }

      final templateDetail = await _contractTemplateRepo.getTemplateById(newContractDetail.templateId!);
      final areaDetail = await _areaRepo.getAreaById(currentAreaId);

      int durationMonths = 0;
      final startDate = DateTime.tryParse(newContractDetail.startDate);
      if (startDate != null && newEndDate != null) {
        durationMonths = (newEndDate!.difference(startDate).inDays / 30).round();
      }

      int paymentDay = areaDetail.invoiceDay ?? 1;

      final pdfBytes = await ContractPdfService.generateContractPdf(
        templateName: templateDetail.name ?? "HỢP ĐỒNG THUÊ PHÒNG TRỌ",
        rentalContent: templateDetail.rentalContent ?? "",
        landlordDuty: templateDetail.landlordDuty ?? "",
        tenantDuty: templateDetail.tenantDuty ?? "",
        executionTerms: templateDetail.executionTerms ?? "",
        landlordName: newContractDetail.landlordName,
        landlordIdCard: newContractDetail.landlordIdCardNumber,
        landlordAddress: newContractDetail.landlordHometown,
        tenantName: newContractDetail.tenantName,
        tenantIdCard: newContractDetail.tenantIdCardNumber,
        tenantAddress: newContractDetail.tenantHometown,
        roomNumber: newContractDetail.roomNumber,
        roomAddress: areaDetail.address,
        rentPrice: newContractDetail.rentPrice,
        depositAmount: newContractDetail.depositAmount,
        durationMonths: durationMonths,
        paymentDay: paymentDay,
        startDate: newContractDetail.startDate,
        endDate: newContractDetail.endDate,
        createdDate: newContractDetail.createdAt != null
            ? DateTime.tryParse(newContractDetail.createdAt!) ?? DateTime.now()
            : DateTime.now(),
        landlordSignatureUrl: newContractDetail.landlordSignatureUrl ?? "",
      );

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/hop_dong_gia_han_$newContractId.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      await _contractRepo.uploadContractFile(newContractId, tempFile);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

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