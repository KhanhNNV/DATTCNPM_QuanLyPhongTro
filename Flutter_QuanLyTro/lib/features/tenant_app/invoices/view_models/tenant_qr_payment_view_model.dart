import 'package:flutter/material.dart';
import '../../../../data/models/response/payment_qr_response.dart';
import '../../../../data/repository/invoice_repository.dart';

class TenantQrPaymentViewModel extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();
  final String invoiceId;

  bool isLoading = true;
  String? errorMessage;
  PaymentQrResponse? qrResponse;

  TenantQrPaymentViewModel({required this.invoiceId}) {
    fetchQrCode();
  }

  Future<void> fetchQrCode() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      qrResponse = await _repository.getPaymentQrCode(invoiceId);
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}