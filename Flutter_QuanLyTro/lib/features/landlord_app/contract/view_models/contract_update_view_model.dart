import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/contract_pdf_service.dart';
import '../../../../data/models/response/contract_detail_response.dart';
import '../../../../data/repository/area_repository.dart';
import '../../../../data/repository/contract_repository.dart';
import '../../../../data/repository/contract_template_repository.dart';

class ContractUpdateViewModel extends ChangeNotifier {
  final ContractRepository _contractRepo = ContractRepository();
  final ContractTemplateRepository _contractTemplateRepository = ContractTemplateRepository();
  final AreaRepository _areaRepo = AreaRepository();

  final ContractDetailResponse currentContract;
  final String areaId;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final TextEditingController depositAmountController = TextEditingController();
  final TextEditingController tenantNameController = TextEditingController();
  final TextEditingController tenantIdCardNumberController = TextEditingController();
  final TextEditingController tenantHometownController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  DateTime? tenantDob;

  ContractUpdateViewModel({
    required this.currentContract,
    required this.areaId,
  }) {
    _initData();
  }

  void _initData() {
    depositAmountController.text = currentContract.depositAmount.toInt().toString();
    tenantNameController.text = currentContract.tenantName;
    tenantIdCardNumberController.text = currentContract.tenantIdCardNumber ?? '';
    tenantHometownController.text = currentContract.tenantHometown ?? '';

    try {
      startDate = DateTime.parse(currentContract.startDate);
      endDate = DateTime.parse(currentContract.endDate);
    } catch (e) {
      debugPrint('Lỗi parse ngày tháng: $e');
    }
  }

  void changeStartDate(DateTime date) { startDate = date; notifyListeners(); }
  void changeEndDate(DateTime date) { endDate = date; notifyListeners(); }
  void changeTenantDob(DateTime date) { tenantDob = date; notifyListeners(); }

  Future<void> submitUpdate() async {
    if (!formKey.currentState!.validate()) return;
    if (startDate == null || endDate == null) throw Exception("Vui lòng chọn thời hạn hợp đồng");

    isLoading = true;
    notifyListeners();

    File? tempFile;

    try {
      if (currentContract.templateId == null) {
        throw Exception("Hợp đồng này không tồn tại Template ID để cập nhật!");
      }

      final templateDetail = await _contractTemplateRepository.getTemplateById(currentContract.templateId!);
      final areaDetail = await _areaRepo.getAreaById(areaId);

      int durationMonths = (endDate!.difference(startDate!).inDays / 30).round();
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
        tenantName: tenantNameController.text.trim(),
        tenantIdCard: tenantIdCardNumberController.text.trim(),
        tenantAddress: tenantHometownController.text.trim(),
        roomNumber: currentContract.roomNumber,
        roomAddress: areaDetail.address,
        rentPrice: currentContract.rentPrice,
        depositAmount: double.tryParse(depositAmountController.text.trim()) ?? 0.0,
        durationMonths: durationMonths,
        paymentDay: paymentDay,
        createdDate: currentContract.createdAt != null
            ? DateTime.tryParse(currentContract.createdAt!) ?? DateTime.now()
            : DateTime.now(),
        landlordSignatureUrl: currentContract.landlordSignatureUrl ?? "",
      );

      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/hop_dong_update_${currentContract.id}.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      final updateData = {
        "startDate": DateFormat('yyyy-MM-dd').format(startDate!),
        "endDate": DateFormat('yyyy-MM-dd').format(endDate!),
        "depositAmount": double.parse(depositAmountController.text.trim()),
        "templateId": currentContract.templateId,
        "tenantFullName": tenantNameController.text.trim(),
        "tenantIdCardNumber": tenantIdCardNumberController.text.trim(),
        "tenantDob": tenantDob != null ? DateFormat('yyyy-MM-dd').format(tenantDob!) : null,
        "tenantHometown": tenantHometownController.text.trim(),
        "members": [],
      };

      await _contractRepo.updateContract(
        contractId: currentContract.id,
        data: updateData,
        file: tempFile,
      );

    } catch (e) {
      rethrow;
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
      isLoading = false;
      notifyListeners();
    }
  }
}