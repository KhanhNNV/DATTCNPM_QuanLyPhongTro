import 'package:flutter/material.dart';
import '../../../../data/models/response/invoice_detail_response.dart';
import '../../../../data/repository/invoice_repository.dart';

class TenantInvoiceDetailViewModel extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();

  bool isLoading = true;
  String? errorMessage;
  InvoiceDetailResponse? invoiceDetail;
  bool isPaying = false; // Trạng thái khi đang gọi API thanh toán

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

  // TODO: Hàm xử lý thanh toán (Tích hợp VNPay, MoMo, hoặc báo cáo thanh toán)
  Future<void> payInvoice() async {
    if (invoiceDetail == null) return;

    isPaying = true;
    notifyListeners();

    try {
      // Giả lập gọi API thanh toán mất 2 giây
      await Future.delayed(const Duration(seconds: 2));

      // Thành công thì load lại dữ liệu để cập nhật trạng thái PAID
      await fetchInvoiceDetail(invoiceDetail!.id);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isPaying = false;
      notifyListeners();
    }
  }
}