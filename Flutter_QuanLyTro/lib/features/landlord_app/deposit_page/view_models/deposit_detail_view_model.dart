import 'package:flutter/material.dart';
import '../../../../data/models/response/deposit_response.dart';
import '../../../../data/repository/deposit_repository.dart';

class DepositDetailViewModel extends ChangeNotifier {
  final DepositRepository _repository = DepositRepository();

  DepositResponse? currentDeposit; // Biến lưu giữ liệu hiện tại
  bool isDeleting = false;
  bool isReloading = false; // Trạng thái khi đang gọi API update lại màn hình

  // nhận data từ màn hình List truyền sang lúc mới mở
  void initData(DepositResponse deposit) {
    currentDeposit = deposit;
  }

  // gọi API getById để lấy data mới nhất sau khi Edit thành công
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