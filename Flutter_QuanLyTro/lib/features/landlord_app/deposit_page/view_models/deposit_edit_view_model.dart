import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/request/deposit_update_request.dart';
import '../../../../data/models/response/deposit_response.dart';
import '../../../../data/repository/deposit_repository.dart';

class DepositEditViewModel extends ChangeNotifier {
  final DepositRepository _repository = DepositRepository();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late String depositId;
  String roomNumber = '';

  final TextEditingController tenantController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController depositController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  DateTime? expectedMoveInDate;
  String selectedStatus = 'PENDING';
  bool isLoading = false;

  final List<String> statusOptions = ['PENDING', 'COMPLETED', 'CANCELLED'];

  void initData(DepositResponse deposit) {
    depositId = deposit.id;
    roomNumber = deposit.roomNumber;
    tenantController.text = deposit.tenantFullName;
    phoneController.text = deposit.phone;
    depositController.text = deposit.depositAmount.toStringAsFixed(0);
    noteController.text = deposit.note ?? '';
    selectedStatus = deposit.status;

    if (deposit.expectedMoveInDate != null && deposit.expectedMoveInDate!.isNotEmpty) {
      try {
        expectedMoveInDate = DateTime.parse(deposit.expectedMoveInDate!);
      } catch (_) {}
    }
  }

  void changeExpectedDate(DateTime date) {
    expectedMoveInDate = date;
    notifyListeners();
  }

  void changeStatus(String? newValue) {
    if (newValue != null) {
      selectedStatus = newValue;
      notifyListeners();
    }
  }

  Future<void> saveUpdate() async {
    if (!formKey.currentState!.validate()) return;
    if (expectedMoveInDate == null) {
      throw Exception('Vui lòng chọn ngày dự kiến vào ở');
    }

    isLoading = true;
    notifyListeners();

    try {
      final request = DepositUpdateRequest(
        phone: phoneController.text.trim(),
        tenantFullName: tenantController.text.trim(),
        depositAmount: double.parse(depositController.text.trim()),
        expectedMoveInDate: DateFormat('yyyy-MM-dd').format(expectedMoveInDate!),
        note: noteController.text.trim(),
        status: selectedStatus,
      );

      await _repository.updateDeposit(depositId, request);
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    tenantController.dispose();
    phoneController.dispose();
    depositController.dispose();
    noteController.dispose();
    super.dispose();
  }
}