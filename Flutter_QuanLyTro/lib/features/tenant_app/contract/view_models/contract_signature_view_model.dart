import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../data/repository/contract_repository.dart';

class ContractSignatureViewModel extends ChangeNotifier {
  final ContractRepository _contractRepo = ContractRepository();
  final String contractId;

  ContractSignatureViewModel({required this.contractId});

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

    try {
      final Uint8List? imageBytes = await signatureController.toPngBytes();
      if (imageBytes == null) {
        throw Exception('Không thể xuất dữ liệu chữ ký!');
      }

      // Gọi API Ký hợp đồng
      await _contractRepo.signContract(contractId, imageBytes);
      return true; // Ký thành công
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSignature() {
    signatureController.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }
}