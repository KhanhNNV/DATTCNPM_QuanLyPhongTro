import 'package:flutter/material.dart';
import '../../../../data/models/response/invoice_response.dart';
import '../../../../data/repository/invoice_repository.dart';

class InvoiceListViewModel extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();

  final String? areaId;

  InvoiceListViewModel({this.areaId});

  bool isLoading = false;
  bool isFetchingMore = false;
  String? errorMessage;

  List<InvoiceResponse> _allInvoices = [];
  List<InvoiceResponse> displayedInvoices = [];

  int currentPage = 0;
  int totalPages = 1;
  final int pageSize = 3;
  bool get hasMore => currentPage < totalPages - 1;

  String selectedStatus = 'ALL';
  String searchQuery = '';

  final Map<String, String> statusMap = {
    'ALL': 'Tất cả',
    'UNPAID': 'Chưa thanh toán',
    'PAID': 'Đã thanh toán',
    'OVERDUE': 'Quá hạn',
    'PENDING': 'Chờ xác nhận'
  };

  Future<void> fetchInvoices({bool isRefresh = true}) async {
    if (isRefresh) {
      currentPage = 0;
      _allInvoices.clear();
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
      final result = await _repository.getAllInvoicesForLandlord(
        page: currentPage,
        size: pageSize,
        status: selectedStatus == 'ALL' ? null : selectedStatus,
        areaId: areaId,
      );

      _allInvoices.addAll(result['invoices'] as List<InvoiceResponse>);
      totalPages = result['totalPages'] as int;

      _applyLocalFilter();
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


  void onSearchChanged(String query) {
    searchQuery = query;
    _applyLocalFilter();
  }


  void _applyLocalFilter() {
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      displayedInvoices = _allInvoices
          .where((inv) => inv.roomNumber.toLowerCase().contains(query))
          .toList();
    } else {
      displayedInvoices = List<InvoiceResponse>.from(_allInvoices);
    }
    notifyListeners();
  }

  void updateLocalInvoice(InvoiceResponse updatedInvoice) {
    final index = _allInvoices.indexWhere((i) => i.id == updatedInvoice.id);
    if (index != -1) {
      _allInvoices[index] = updatedInvoice;
      _applyLocalFilter();
    }
  }
}