import 'package:flutter/material.dart';
import '../../../../data/models/response/contract_detail_response.dart';
import '../../../../data/repository/contract_repository.dart';

class ContractListViewModel extends ChangeNotifier {
  final ContractRepository _repository = ContractRepository();

  final String areaId;

  ContractListViewModel({required this.areaId});

  // --- QUẢN LÝ STATE TÌM KIẾM ---
  final TextEditingController searchController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  List<ContractDetailResponse> _allContracts = [];
  List<ContractDetailResponse> displayedContracts = [];

  String selectedStatus = 'ALL';
  String searchQuery = '';

  // Ánh xạ trạng thái hiển thị
  final Map<String, String> statusMap = {
    'ALL': 'Tất cả',
    'DRAFT': 'Bản nháp',
    'SIGNED': 'Đã ký',
    'EXPIRED': 'Đã hết hạn',
    'TERMINATED': 'Đã thanh lý',
  };

  Future<void> fetchContracts() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      _allContracts = await _repository.getMyContracts(areaId);

      _applyFilters();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
    }
  }

  void changeStatus(String status) {
    if (selectedStatus != status) {
      selectedStatus = status;
      _applyFilters();
    }
  }

  void onSearchChanged(String query) {
    searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    List<ContractDetailResponse> results = List.from(_allContracts);

    // 1. Lọc theo trạng thái hợp đồng (Local filter)
    if (selectedStatus != 'ALL') {
      results = results.where((c) => c.status == selectedStatus).toList();
    }

    // 2. Lọc theo từ khóa tìm kiếm (Số phòng hoặc Tên khách thuê)
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      results = results.where((c) {
        final matchRoom = c.roomNumber.toLowerCase().contains(query);
        final matchTenant = c.tenantName.toLowerCase().contains(query);
        return matchRoom || matchTenant;
      }).toList();
    }

    displayedContracts = results;
    isLoading = false;
    notifyListeners();
  }

  Future<String> deleteContract(String contractId) async {
    try {
      final successMessage = await _repository.deleteContract(contractId);
      _allContracts.removeWhere((c) => c.id == contractId);
      _applyFilters();

      return successMessage;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}