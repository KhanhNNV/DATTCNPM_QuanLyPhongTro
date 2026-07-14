import 'package:flutter/material.dart';
import '../../../../data/models/response/deposit_response.dart';
import '../../../../data/repository/deposit_repository.dart';

class DepositDetailViewModel extends ChangeNotifier {
  final DepositRepository _repository = DepositRepository();

  DepositResponse? currentDeposit;
  bool isDeleting = false;
  bool isReloading = false;


  void initData(DepositResponse deposit) {
    currentDeposit = deposit;
  }


  Future<void> reloadDepositData() async {
    if (currentDeposit == null) return;
    try {
      isReloading = true;
      notifyListeners();

      currentDeposit = await _repository.getDepositById(currentDeposit!.id);
    } catch (e) {
    } finally {
      isReloading = false;
      notifyListeners();
    }
  }

}