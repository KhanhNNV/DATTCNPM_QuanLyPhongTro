import 'package:flutter/material.dart';
import '../../../../data/models/request/deposit_create_request.dart';
import '../../../../data/models/response/room_model.dart';
import '../../../../data/repository/deposit_repository.dart';
import '../../../../data/repository/room_repository.dart';

class DepositViewModel extends ChangeNotifier {
  final RoomRepository roomProvider = RoomRepository();
  final DepositRepository depositProvider = DepositRepository();

  // --- QUẢN LÝ FORM STATE ---
  final formKey = GlobalKey<FormState>();
  final tenantController = TextEditingController();
  final phoneController = TextEditingController();
  final depositController = TextEditingController();
  final noteController = TextEditingController();
  DateTime? expectedMoveInDate;

  bool isLoading = false;
  List<RoomModel> rooms = [];
  RoomModel? selectedRoom;

  Future<void> loadRooms(String areaId) async {
    try {
      isLoading = true;
      notifyListeners();
      rooms = await roomProvider.getRoomsByArea(areaId, status: "AVAILABLE");
    } catch (e) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectRoom(RoomModel room) {
    selectedRoom = room;
    depositController.text = room.depositAmount.toStringAsFixed(0);
    notifyListeners();
  }

  void changeExpectedDate(DateTime date) {
    expectedMoveInDate = date;
    notifyListeners();
  }

  // --- HÀM LƯU PHIẾU ĐẶT CỌC ---
  Future<void> saveDeposit() async {
    if (!formKey.currentState!.validate()) {
      throw Exception('Vui lòng điền đầy đủ thông tin hợp lệ!');
    }
    if (selectedRoom == null) {
      throw Exception('Vui lòng chọn phòng!');
    }
    if (expectedMoveInDate == null) {
      throw Exception('Vui lòng chọn ngày dự kiến vào ở!');
    }

    try {
      isLoading = true;
      notifyListeners();

      final request = DepositCreateRequest(
        roomId: selectedRoom!.id,
        phone: phoneController.text.trim(),
        tenantFullName: tenantController.text.trim(),
        depositAmount: double.parse(depositController.text.trim()),
        expectedMoveInDate: expectedMoveInDate!.toIso8601String().split('T').first,
        note: noteController.text.trim(),
      );

      await depositProvider.createDeposit(request);
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