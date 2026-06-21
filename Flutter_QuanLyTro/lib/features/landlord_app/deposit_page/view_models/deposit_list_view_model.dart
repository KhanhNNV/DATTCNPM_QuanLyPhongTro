import 'package:flutter/material.dart';
import '../../../../data/models/response/deposit_response.dart';
import '../../../../data/repository/deposit_repository.dart';

class DepositListViewModel extends ChangeNotifier {
  final DepositRepository _repository = DepositRepository();

  bool isLoading = false;
  String? errorMessage;

  // Lưu danh sách gốc từ API
  List<DepositResponse> _allDeposits = [];
  // Danh sách thực tế sẽ hiển thị lên màn hình (sau khi tìm kiếm)
  List<DepositResponse> displayedDeposits = [];

  // Trạng thái lọc hiện tại
  String selectedStatus = 'ALL';
  String searchQuery = '';

  // Ánh xạ trạng thái để hiển thị UI
  final Map<String, String> statusMap = {
    'ALL': 'Tất cả',
    'PENDING': 'Đang giữ chỗ',
    'COMPLETED': 'Đã hoàn thành',
    'CANCELLED': 'Đã hủy',
  };

  Future<void> fetchDeposits(String areaId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      _allDeposits = await _repository.getDepositsByAreaId(
        areaId,
        status: selectedStatus == 'ALL' ? null : selectedStatus,
      );

      // Sau khi lấy data từ API, áp dụng luôn bộ lọc tìm kiếm text
      _applyLocalSearch();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
    }
  }

  // Khi chọn chip trạng thái mới
  void changeStatus(String status, String areaId) {
    if (selectedStatus != status) {
      selectedStatus = status;
      fetchDeposits(areaId); // Gọi lại API vì Backend xử lý lọc status
    }
  }

  // Khi gõ text tìm kiếm
  void onSearchChanged(String query) {
    searchQuery = query;
    _applyLocalSearch();
  }

  void _applyLocalSearch() {
    if (searchQuery.trim().isEmpty) {
      displayedDeposits = List.from(_allDeposits);
    } else {
      final query = searchQuery.trim().toLowerCase();
      displayedDeposits = _allDeposits.where((deposit) {
        final matchName = deposit.tenantFullName.toLowerCase().contains(query);
        final matchPhone = deposit.phone.toLowerCase().contains(query);
        return matchName || matchPhone;
      }).toList();
    }
    isLoading = false;
    notifyListeners();
  }

  // --- hàm cập nhâ cục bộ trên RAM ---

  // Thêm mới vào đầu danh sách
  void addLocalDeposit(DepositResponse newDeposit) {
    _allDeposits.insert(0, newDeposit);
    _applyLocalSearch();
  }

  // Cập nhật phần tử bị sửa
  void updateLocalDeposit(DepositResponse updatedDeposit) {
    final index = _allDeposits.indexWhere((d) => d.id == updatedDeposit.id);
    if (index != -1) {
      _allDeposits[index] = updatedDeposit;
      _applyLocalSearch();
    }
  }

  // Xóa phần tử
  void deleteLocalDeposit(String depositId) {
    _allDeposits.removeWhere((d) => d.id == depositId);
    _applyLocalSearch();
  }
}