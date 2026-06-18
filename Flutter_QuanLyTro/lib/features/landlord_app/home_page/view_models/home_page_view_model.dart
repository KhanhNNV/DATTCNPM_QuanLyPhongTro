import 'package:flutter/material.dart';

import '../../../../data/models/response/room_model.dart';
import '../../../../data/repository/room_repository.dart';

class HomePageViewModel extends ChangeNotifier {
  final RoomRepository _roomProvider = RoomRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<RoomModel> _rooms = [];
  List<RoomModel> get rooms => _rooms;

  Future<void> loadRooms(String areaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rooms = await _roomProvider.getRoomsByArea(areaId);
    } catch (e) {
      _errorMessage =
          e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}