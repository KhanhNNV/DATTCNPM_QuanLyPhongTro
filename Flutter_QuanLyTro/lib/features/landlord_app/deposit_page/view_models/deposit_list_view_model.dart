import 'package:flutter/material.dart';
import '../../../../data/models/response/deposit_response.dart';
import '../../../../data/repository/deposit_repository.dart';

class DepositListViewModel extends ChangeNotifier {
  final DepositRepository _repository = DepositRepository();

  bool isLoading = false;
  List<DepositResponse> deposits = [];
  String? errorMessage;

  Future<void> fetchDeposits(String areaId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      deposits = await _repository.getDepositsByAreaId(areaId);
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}