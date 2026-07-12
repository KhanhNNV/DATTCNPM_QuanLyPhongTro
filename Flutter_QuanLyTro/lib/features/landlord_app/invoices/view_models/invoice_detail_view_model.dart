import 'package:flutter/material.dart';
import '../../../../data/models/response/invoice_detail_response.dart';
import '../../../../data/repository/invoice_repository.dart';

class InvoiceDetailViewModel extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();

  bool isLoading = true;
  String? errorMessage;
  InvoiceDetailResponse? invoiceDetail;

  Future<void> fetchInvoiceDetail(String id) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      invoiceDetail = await _repository.getInvoiceDetail(id);
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}