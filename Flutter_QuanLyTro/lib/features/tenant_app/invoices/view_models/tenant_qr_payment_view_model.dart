import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../data/models/response/payment_qr_response.dart';
import '../../../../data/repository/invoice_repository.dart';


class TenantQrPaymentViewModel extends ChangeNotifier {
  final String invoiceId;
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  PaymentQrResponse? _qrResponse;
  PaymentQrResponse? get qrResponse => _qrResponse;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  TenantQrPaymentViewModel({required this.invoiceId}) {
    fetchQrCode();
  }

  Future<void> fetchQrCode() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _qrResponse = await _invoiceRepository.getPaymentQrCode(invoiceId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProofImage(File imageFile) async {
    _isUploading = true;
    notifyListeners();

    try {
      await _invoiceRepository.uploadPaymentProof(invoiceId, imageFile);

      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploading = false;
      notifyListeners();

      return false;
    }
  }
}