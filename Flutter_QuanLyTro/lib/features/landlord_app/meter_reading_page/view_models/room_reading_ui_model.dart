import 'package:flutter/material.dart';

// Mapping chính xác với Enum ServiceCalculationType của Backend
enum ServiceCalculationType {
  byIndex,   // BY_INDEX
  perPerson, // PER_PERSON
  perRoom    // PER_ROOM
}

class RoomReadingUiModel {
  final String roomId;
  final String roomNumber;

  // Lưu loại tính giá của dịch vụ điện/nước lấy từ AreaService
  final ServiceCalculationType? elecCalcType;
  final ServiceCalculationType? waterCalcType;

  // ID bản ghi tháng này (nếu đã chốt trước đó thì khác null -> Dùng để UPDATE)
  String? elecReadingId;
  String? waterReadingId;

  // Chỉ số cũ
  final int elecOldIndex;
  final int waterOldIndex;

  // Controller quản lý ô nhập liệu
  late TextEditingController elecController;
  late TextEditingController waterController;

  RoomReadingUiModel({
    required this.roomId,
    required this.roomNumber,
    this.elecCalcType,
    this.waterCalcType,
    required this.elecOldIndex,
    required this.waterOldIndex,
    int? elecNewIndex,
    int? waterNewIndex,
    this.elecReadingId,
    this.waterReadingId,
  }) {
    elecController = TextEditingController(text: elecNewIndex?.toString() ?? '');
    waterController = TextEditingController(text: waterNewIndex?.toString() ?? '');
  }

  // Sử dụng Getter để UI vẫn hoạt động mượt mà như cũ không cần sửa đổi Code Screen
  bool get isElecByIndex => elecCalcType == ServiceCalculationType.byIndex;
  bool get isWaterByIndex => waterCalcType == ServiceCalculationType.byIndex;

  void dispose() {
    elecController.dispose();
    waterController.dispose();
  }
}