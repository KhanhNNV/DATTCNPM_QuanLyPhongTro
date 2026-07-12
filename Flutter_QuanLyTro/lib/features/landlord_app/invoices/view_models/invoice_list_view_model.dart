import 'package:flutter/material.dart';
import '../../../../data/models/response/invoice_response.dart';
import '../../../../data/repository/invoice_repository.dart';

class InvoiceListViewModel extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();

  bool isLoading = false;
  String? errorMessage;

  // Lưu danh sách gốc từ API
  List<InvoiceResponse> _allInvoices = [];

  // Danh sách thực tế sẽ hiển thị lên màn hình (sau khi tìm kiếm & lọc status)
  List<InvoiceResponse> displayedInvoices = [];

  // Trạng thái lọc hiện tại
  String selectedStatus = 'ALL';
  String searchQuery = '';

  // Ánh xạ trạng thái để hiển thị UI (Tùy chỉnh theo Enum của Backend)
  final Map<String, String> statusMap = {
    'ALL': 'Tất cả',
    'UNPAID': 'Chưa thanh toán',
    'PAID': 'Đã thanh toán',
    'OVERDUE': 'Quá hạn',
  };

  Future<void> fetchInvoices() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // Gọi API không cần truyền tham số status
      _allInvoices = await _repository.getAllInvoicesForLandlord();

      // Áp dụng bộ lọc tìm kiếm và trạng thái ngay sau khi có dữ liệu
      _applyLocalSearch();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
    }
  }

  // Khi chọn chip trạng thái mới
  void changeStatus(String status) {
    if (selectedStatus != status) {
      selectedStatus = status;
      // Vì API đã trả về tất cả, ta chỉ cần lọc lại cục bộ (không tốn request API)
      _applyLocalSearch();
    }
  }

  // Khi gõ text tìm kiếm (Lọc theo phòng)
  void onSearchChanged(String query) {
    searchQuery = query;
    _applyLocalSearch();
  }

  void _applyLocalSearch() {
    var filteredList = List<InvoiceResponse>.from(_allInvoices);

    // 1. Lọc theo trạng thái
    if (selectedStatus != 'ALL') {
      filteredList = filteredList.where((inv) => inv.status == selectedStatus).toList();
    }

    // 2. Lọc theo text tìm kiếm (Số phòng)
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      filteredList = filteredList.where((inv) {
        return inv.roomNumber.toLowerCase().contains(query);
      }).toList();
    }

    displayedInvoices = filteredList;
    isLoading = false;
    notifyListeners();
  }

  // --- Hỗ trợ cập nhật cục bộ ---
  void updateLocalInvoice(InvoiceResponse updatedInvoice) {
    final index = _allInvoices.indexWhere((i) => i.id == updatedInvoice.id);
    if (index != -1) {
      _allInvoices[index] = updatedInvoice;
      _applyLocalSearch();
    }
  }
}