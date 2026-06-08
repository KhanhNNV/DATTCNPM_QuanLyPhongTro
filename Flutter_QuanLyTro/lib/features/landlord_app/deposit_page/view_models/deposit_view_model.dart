import 'package:flutter/material.dart';

import '../../../../data/models/request/deposit_create_request.dart';
import '../../../../data/models/response/room_model.dart';
import '../../../../data/providers/deposit_provider.dart';
import '../../../../data/providers/room_provider.dart';



class DepositViewModel extends ChangeNotifier {

  final RoomProvider roomProvider =
  RoomProvider();

  final DepositProvider depositProvider =
  DepositProvider();

  bool isLoading = false;

  List<RoomModel> rooms = [];

  RoomModel? selectedRoom;

  Future<void> loadRooms(
      String areaId) async {

    try {
      isLoading = true;
      notifyListeners();

      rooms = await roomProvider.getRoomsByArea(
        areaId,
        status: "AVAILABLE",
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectRoom(RoomModel room) {
    selectedRoom = room;
    notifyListeners();
  }

  Future<void> createDeposit(
      DepositCreateRequest request) async {

    await depositProvider.createDeposit(
      request,
    );
  }
}