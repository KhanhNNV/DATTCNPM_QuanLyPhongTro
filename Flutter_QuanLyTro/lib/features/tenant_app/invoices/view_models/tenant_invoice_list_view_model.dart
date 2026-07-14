import 'package:flutter/material.dart';
import '../../../../data/models/response/invoice_response.dart';
import '../../../../data/repository/invoice_repository.dart';

class TenantInvoiceListViewModel extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();

  bool isLoading = false;
  bool isFetchingMore = false;
  String? errorMessage;

  List<InvoiceResponse> invoices = [];


  int currentPage = 0;
  int totalPages = 1;
  final int pageSize = 10;
  bool get hasMore => currentPage < totalPages - 1;


  String selectedStatus = 'ALL';

  final Map<String, String> statusMap = {
    'ALL': 'Tất cả',
    'UNPAID': 'Chưa thanh toán',
    'PAID': 'Đã thanh toán',
    'OVERDUE': 'Quá hạn',
    'PENDING': 'Chờ xác nhận',
  };

  Future<void> fetchInvoices({bool isRefresh = true}) async {
    if (isRefresh) {
      currentPage = 0;
      invoices.clear();
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    } else {
      if (!hasMore || isFetchingMore) return;
      isFetchingMore = true;
      currentPage++;
      notifyListeners();
    }

    try {
      final result = await _repository.getMyInvoices(
        page: currentPage,
        size: pageSize,
        status: selectedStatus == 'ALL' ? null : selectedStatus,
      );

      invoices.addAll(result['invoices'] as List<InvoiceResponse>);
      totalPages = result['totalPages'] as int;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!isRefresh && currentPage > 0) currentPage--;
    } finally {
      isLoading = false;
      isFetchingMore = false;
      notifyListeners();
    }
  }

  void changeStatus(String status) {
    if (selectedStatus != status) {
      selectedStatus = status;
      fetchInvoices(isRefresh: true);
    }
  }
}