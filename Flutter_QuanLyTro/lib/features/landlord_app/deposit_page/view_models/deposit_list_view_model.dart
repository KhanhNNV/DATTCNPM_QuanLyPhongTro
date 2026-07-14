import 'package:flutter/material.dart';
import '../../../../data/models/response/deposit_response.dart';
import '../../../../data/repository/deposit_repository.dart';

class DepositListViewModel extends ChangeNotifier {
  final DepositRepository _repository = DepositRepository();

  bool isLoading = false;
  String? errorMessage;


  List<DepositResponse> _allDeposits = [];

  List<DepositResponse> displayedDeposits = [];


  String selectedStatus = 'ALL';
  String searchQuery = '';


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


      _applyLocalSearch();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
    }
  }


  void changeStatus(String status, String areaId) {
    if (selectedStatus != status) {
      selectedStatus = status;
      fetchDeposits(areaId);
    }
  }


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

  void addLocalDeposit(DepositResponse newDeposit) {
    _allDeposits.insert(0, newDeposit);
    _applyLocalSearch();
  }


  void updateLocalDeposit(DepositResponse updatedDeposit) {
    final index = _allDeposits.indexWhere((d) => d.id == updatedDeposit.id);
    if (index != -1) {
      _allDeposits[index] = updatedDeposit;
      _applyLocalSearch();
    }
  }


  void deleteLocalDeposit(String depositId) {
    _allDeposits.removeWhere((d) => d.id == depositId);
    _applyLocalSearch();
  }
}