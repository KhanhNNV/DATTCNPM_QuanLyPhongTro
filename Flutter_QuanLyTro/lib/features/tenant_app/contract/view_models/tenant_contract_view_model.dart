import 'package:flutter/material.dart';
import '../../../../data/models/response/contract_detail_response.dart';
import '../../../../data/repository/contract_repository.dart';

class TenantContractViewModel extends ChangeNotifier {
  final ContractRepository _contractRepo = ContractRepository();

  ContractDetailResponse? currentContract;
  bool isLoading = true;
  String? errorMessage;

  // Hàm tải dữ liệu hợp đồng
  Future<void> loadCurrentContract() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentContract = await _contractRepo.getMyCurrentContract();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}