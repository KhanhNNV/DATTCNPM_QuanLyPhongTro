import 'package:flutter/material.dart';
import '../../../../data/models/response/invoice_response.dart';
import '../../../../data/repository/invoice_repository.dart';

/// Quản lý trạng thái và logic của màn hình Danh sách Hóa đơn.
/// Hỗ trợ phân trang (Pagination), tìm kiếm nội bộ và lọc theo trạng thái.
class InvoiceListViewModel extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();

  final String? areaId;

  InvoiceListViewModel({this.areaId});

  // Trạng thái UI
  bool isLoading = false;
  bool isFetchingMore = false;
  String? errorMessage;

  // Dữ liệu
  List<InvoiceResponse> _allInvoices = [];
  List<InvoiceResponse> displayedInvoices = [];

  // Phân trang
  int currentPage = 0;
  int totalPages = 1;
  final int pageSize = 3;
  bool get hasMore => currentPage < totalPages - 1;

  // Trạng thái bộ lọc
  String selectedStatus = 'ALL';
  String searchQuery = '';

  final Map<String, String> statusMap = {
    'ALL': 'Tất cả',
    'UNPAID': 'Chưa thanh toán',
    'PAID': 'Đã thanh toán',
    'OVERDUE': 'Quá hạn',
    'PENDING': 'Chờ xác nhận'
  };

  /// Lấy danh sách hóa đơn từ Server
  /// [isRefresh] = true: Tải lại từ trang 0.
  /// [isRefresh] = false: Tải tiếp trang tiếp theo (Load more).
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
        areaId: areaId, // 🎯 SỬA Ở ĐÂY: Truyền areaId xuống Repository
      );

      _allInvoices.addAll(result['invoices'] as List<InvoiceResponse>);
      totalPages = result['totalPages'] as int;

      _applyLocalFilter();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      if (!isRefresh && currentPage > 0) currentPage--; // Hoàn tác trang nếu lỗi
    } finally {
      isLoading = false;
      isFetchingMore = false;
      notifyListeners();
    }
  }

  /// Thay đổi trạng thái lọc và gọi lại API
  void changeStatus(String status) {
    if (selectedStatus != status) {
      selectedStatus = status;
      fetchInvoices(isRefresh: true);
    }
  }

  /// Cập nhật từ khóa và tìm kiếm trong danh sách đã tải
  void onSearchChanged(String query) {
    searchQuery = query;
    _applyLocalFilter();
  }

  /// Áp dụng bộ lọc tìm kiếm nội bộ dựa trên số phòng
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

  /// Cập nhật thông tin một hóa đơn cụ thể (vd: sau khi thanh toán thành công)
  void updateLocalInvoice(InvoiceResponse updatedInvoice) {
    final index = _allInvoices.indexWhere((i) => i.id == updatedInvoice.id);
    if (index != -1) {
      _allInvoices[index] = updatedInvoice;
      _applyLocalFilter();
    }
  }
}