import 'package:flutter/material.dart';
import '../../../../data/models/request/contract_member_add_request.dart';
import '../../../../data/models/response/contract_detail_response.dart';
import '../../../../data/models/response/room_model.dart';
import '../../../../data/repository/contract_repository.dart';
import '../../../../data/repository/room_repository.dart';

class RoomDetailViewModel extends ChangeNotifier {
  final RoomRepository _roomRepo = RoomRepository();
  final ContractRepository _contractRepo = ContractRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  RoomModel? _room;
  RoomModel? get room => _room;

  ContractDetailResponse? _activeContract;
  ContractDetailResponse? get activeContract => _activeContract;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final idCardController = TextEditingController();
  final hometownController = TextEditingController();

  void clearMemberForm() {
    nameController.clear();
    phoneController.clear();
    dobController.clear();
    idCardController.clear();
    hometownController.clear();
  }

  Future<void> fetchRoomAndMembers(String roomId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _room = await _roomRepo.getRoomById(roomId);

      if (_room?.status == 'RENTED' || _room?.status == 'DEPOSITED' || _room?.status == 'RESERVED') {
        final allContracts = await _contractRepo.getMyContracts();

        final targetContract = allContracts.where((c) {
          return c.roomId == roomId && c.status == 'SIGNED';
        }).firstOrNull;

        if (targetContract != null) {
          _activeContract = await _contractRepo.getContractDetail(targetContract.id!);
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMember() async {
    if (_activeContract == null || _activeContract?.id == null) {
      _errorMessage = "Không tìm thấy hợp đồng hợp lệ để thêm người.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ContractMemberAddRequest(
        contractId: _activeContract!.id!,
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        dob: dobController.text.trim(),
        hometown: hometownController.text.trim(),
        idCardNumber: idCardController.text.trim(),
      );

      _activeContract = await _contractRepo.addContractMember(request);

      clearMemberForm();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    idCardController.dispose();
    hometownController.dispose();
    super.dispose();
  }
}