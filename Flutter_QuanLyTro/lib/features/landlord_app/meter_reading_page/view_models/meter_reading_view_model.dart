import 'package:flutter/material.dart';
import 'room_reading_ui_model.dart';

class MeterReadingViewModel extends ChangeNotifier {
  bool isLoading = false;
  DateTime selectedMonth = DateTime.now();
  List<RoomReadingUiModel> roomList = [];

  void changeMonth(DateTime newMonth) {
    selectedMonth = newMonth;
    loadMeterReadings();
  }

  Future<void> loadMeterReadings() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // MOCK DATA ĐƯỢC CẬP NHẬT THEO ENUM CỦA BACKEND
    roomList = [
      RoomReadingUiModel(
        roomId: 'uuid-room-101',
        roomNumber: '101',
        elecCalcType: ServiceCalculationType.byIndex,  // BY_INDEX
        waterCalcType: ServiceCalculationType.byIndex, // BY_INDEX
        elecOldIndex: 1250,
        waterOldIndex: 430,
      ),
      RoomReadingUiModel(
        roomId: 'uuid-room-102',
        roomNumber: '102',
        elecCalcType: ServiceCalculationType.byIndex,
        waterCalcType: ServiceCalculationType.byIndex,
        elecOldIndex: 2100,
        waterOldIndex: 520,
        elecNewIndex: 2250,   // Đã chốt trước đó
        waterNewIndex: 535,
        elecReadingId: 'uuid-elec-reading-102',
        waterReadingId: 'uuid-water-reading-102',
      ),
      RoomReadingUiModel(
        roomId: 'uuid-room-103',
        roomNumber: '103',
        elecCalcType: ServiceCalculationType.byIndex,
        waterCalcType: ServiceCalculationType.perPerson, // PER_PERSON -> Sẽ tự động ẩn Nước
        elecOldIndex: 940,
        waterOldIndex: 0,
      ),
      RoomReadingUiModel(
        roomId: 'uuid-room-104',
        roomNumber: '104',
        elecCalcType: ServiceCalculationType.perRoom,  // PER_ROOM -> Tự ẩn
        waterCalcType: ServiceCalculationType.perRoom, // PER_ROOM -> Tự ẩn
        elecOldIndex: 0,
        waterOldIndex: 0,
      ),
    ];

    isLoading = false;
    notifyListeners();
  }

  Future<bool> saveSingleRoom(RoomReadingUiModel room) async {
    if (room.isElecByIndex && room.elecController.text.isEmpty) return false;
    if (room.isWaterByIndex && room.waterController.text.isEmpty) return false;

    // TODO: Bổ sung logic gọi Provider gọi API tại đây

    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  void dispose() {
    for (var room in roomList) {
      room.dispose();
    }
    super.dispose();
  }
}