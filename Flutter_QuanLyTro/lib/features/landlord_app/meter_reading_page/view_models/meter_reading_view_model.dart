import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/data/repository/area_repository.dart';
import 'package:flutter_quanlytro/data/repository/room_repository.dart';

import '../../../../data/models/request/meter_reading_bulk_update_request.dart';
import '../../../../data/models/request/meter_reading_create_request.dart';
import '../../../../data/models/response/room_model.dart';
import '../../../../data/repository/area_config_repository.dart';
import '../../../../data/repository/meter_reading_repository.dart';
import '../room_reading_ui_model.dart';

class MeterReadingViewModel extends ChangeNotifier {
  final MeterReadingRepository _provider = MeterReadingRepository();
  final RoomRepository _roomProvider = RoomRepository();
  final AreaConfigRepository _areaConfigProvider = AreaConfigRepository();

  bool isLoading = false;
  DateTime selectedMonth = DateTime.now();
  List<RoomReadingUiModel> roomList = [];

  final String areaId;

  MeterReadingViewModel({required this.areaId});

  void changeMonth(DateTime newMonth) {
    selectedMonth = newMonth;
    loadMeterReadings();
  }

  Future<void> loadMeterReadings() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Lấy danh sách các phòng và dịch vụ trong khu trọ
      final results = await Future.wait([
        _roomProvider.getRoomsByArea(areaId, status: 'RENTED'),
        _areaConfigProvider.getServicesByArea(areaId),
      ]);

      final rooms = results[0] as List<RoomModel>;
      final services = results[1] as List<dynamic>;

      String? elecServiceId;
      String? waterServiceId;

      for (var service in services) {
        final String serviceName = (service['name'] ?? '').toString().toLowerCase();
        if (serviceName.contains('điện')) {
          elecServiceId = service['id'];
        } else if (serviceName.contains('nước')) {
          waterServiceId = service['id'];
        }
      }

      List<RoomReadingUiModel> newRoomList = [];

      // 2. Lấy chỉ số điện nước cho từng phòng
      for (var room in rooms) {
        final readings = await _provider.getMeterReadings(room.id, selectedMonth);

        String? elecReadingId;
        String? waterReadingId;
        int elecOldIndex = 0;
        int waterOldIndex = 0;
        int? elecNewIndex;
        int? waterNewIndex;

        for (var reading in readings) {
          final isVirtualForm = reading.id == null; // <--- CHECK XEM CÓ PHẢI FORM ẢO KHÔNG

          if (reading.serviceName.toLowerCase().contains('điện')) {
            elecReadingId = reading.id;
            elecOldIndex = reading.oldIndex;
            // NẾU LÀ FORM ẢO THÌ ĐỂ NULL ĐỂ Ô NHẬP LIỆU TRỐNG, KHÔNG HIỂN THỊ SỐ 0
            elecNewIndex = isVirtualForm ? null : reading.newIndex;
          } else if (reading.serviceName.toLowerCase().contains('nước')) {
            waterReadingId = reading.id;
            waterOldIndex = reading.oldIndex;
            // TƯƠNG TỰ VỚI NƯỚC
            waterNewIndex = isVirtualForm ? null : reading.newIndex;
          }
        }

        newRoomList.add(
          RoomReadingUiModel(
            roomId: room.id,
            roomNumber: room.roomNumber,
            elecCalcType: ServiceCalculationType.byIndex,
            waterCalcType: ServiceCalculationType.byIndex,
            elecServiceId: elecServiceId,
            waterServiceId: waterServiceId,
            elecOldIndex: elecOldIndex,
            waterOldIndex: waterOldIndex,
            elecNewIndex: elecNewIndex,
            waterNewIndex: waterNewIndex,
            elecReadingId: elecReadingId,
            waterReadingId: waterReadingId,
          ),
        );
      }

      roomList = newRoomList;
    } catch (e) {
      print("Error loading meter readings: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- TRẢ VỀ STRING? ĐỂ CHỨA THÔNG BÁO LỖI (NẾU CÓ) ---
  Future<String?> saveSingleRoom(RoomReadingUiModel room) async {
    if (room.isElecByIndex && room.elecController.text.isEmpty) {
      return 'Vui lòng nhập chỉ số điện!';
    }
    if (room.isWaterByIndex && room.waterController.text.isEmpty) {
      return 'Vui lòng nhập chỉ số nước!';
    }

    isLoading = true;
    notifyListeners();

    try {
      List<MeterReadingCreateRequest> createRequests = [];
      List<MeterReadingBulkUpdateRequest> updateRequests = [];

      final formattedDate = "${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}-01";

      // Chỉ số Điện
      if (room.isElecByIndex) {
        int elecNew = int.parse(room.elecController.text.trim());
        if (elecNew < room.elecOldIndex) throw Exception('Chỉ số điện mới không được nhỏ hơn số cũ!');

        if (room.elecReadingId == null) {
          createRequests.add(MeterReadingCreateRequest(roomId: room.roomId, serviceId: room.elecServiceId!, newIndex: elecNew, readingDate: formattedDate));
        } else {
          updateRequests.add(MeterReadingBulkUpdateRequest(id: room.elecReadingId!, newIndex: elecNew));
        }
      }

      // Chỉ số Nước
      if (room.isWaterByIndex) {
        int waterNew = int.parse(room.waterController.text.trim());
        if (waterNew < room.waterOldIndex) throw Exception('Chỉ số nước mới không được nhỏ hơn số cũ!');

        if (room.waterReadingId == null) {
          createRequests.add(MeterReadingCreateRequest(roomId: room.roomId, serviceId: room.waterServiceId!, newIndex: waterNew, readingDate: formattedDate));
        } else {
          updateRequests.add(MeterReadingBulkUpdateRequest(id: room.waterReadingId!, newIndex: waterNew));
        }
      }

      // Gửi API
      if (createRequests.isNotEmpty) await _provider.createBulkMeterReadings(createRequests);
      if (updateRequests.isNotEmpty) await _provider.updateBulkMeterReadings(updateRequests);

      // Reload lại dữ liệu mới
      await loadMeterReadings();

      return null; // THÀNH CÔNG -> Trả về null
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return e.toString().replaceAll('Exception: ', ''); // LỖI -> Trả về thông báo lỗi
    }
  }

  @override
  void dispose() {
    for (var room in roomList) {
      room.dispose();
    }
    super.dispose();
  }
}