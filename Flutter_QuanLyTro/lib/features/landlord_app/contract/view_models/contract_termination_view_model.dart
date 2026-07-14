import 'package:flutter/material.dart';
import '../../../../data/models/request/contract_termination_request.dart';
import '../../../../data/models/response/contract_detail_response.dart';
import '../../../../data/models/response/contract_termination_response.dart';
import '../../../../data/repository/contract_repository.dart';

class ContractTerminationViewModel extends ChangeNotifier {
  final ContractRepository _contractRepository = ContractRepository();
  final String areaId;

  ContractTerminationViewModel({required this.areaId});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ContractDetailResponse> _activeContracts = [];
  List<ContractDetailResponse> get activeContracts => _activeContracts;

  String? _selectedContractId;
  String? get selectedContractId => _selectedContractId;

  final TextEditingController electricityController = TextEditingController();
  final TextEditingController waterController = TextEditingController();

  @override
  void dispose() {
    electricityController.dispose();
    waterController.dispose();
    super.dispose();
  }

  Future<void> fetchActiveContracts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final contracts = await _contractRepository.getMyContracts(areaId);
      _activeContracts = contracts.where((c) => c.status == 'SIGNED').toList();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectContract(String? contractId) {
    _selectedContractId = contractId;
    notifyListeners();
  }

  Future<ContractTerminationResponse?> submitTermination() async {
    if (_selectedContractId == null) {
      _errorMessage = 'Vui lòng chọn phòng/hợp đồng cần thanh lý';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final int? electricityUsage = int.tryParse(electricityController.text);
      final int? waterUsage = int.tryParse(waterController.text);

      final request = ContractTerminationRequest(
        electricityUsage: electricityUsage,
        waterUsage: waterUsage,
      );

      final response = await _contractRepository.terminateContract(_selectedContractId!, request);

      _selectedContractId = null;
      electricityController.clear();
      waterController.clear();

      await fetchActiveContracts();

      return response;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}