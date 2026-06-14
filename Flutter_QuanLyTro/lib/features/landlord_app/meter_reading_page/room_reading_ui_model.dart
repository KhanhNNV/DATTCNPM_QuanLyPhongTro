import 'package:flutter/material.dart';

enum ServiceCalculationType {
  byIndex,
  perPerson,
  perRoom
}

class RoomReadingUiModel {
  final String roomId;
  final String roomNumber;

  final ServiceCalculationType? elecCalcType;
  final ServiceCalculationType? waterCalcType;

  final String? elecServiceId;
  final String? waterServiceId;

  String? elecReadingId;
  String? waterReadingId;

  final int elecOldIndex;
  final int waterOldIndex;

  late TextEditingController elecController;
  late TextEditingController waterController;

  RoomReadingUiModel({
    required this.roomId,
    required this.roomNumber,
    this.elecCalcType,
    this.waterCalcType,
    this.elecServiceId,
    this.waterServiceId,
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

  bool get isElecByIndex => elecCalcType == ServiceCalculationType.byIndex;
  bool get isWaterByIndex => waterCalcType == ServiceCalculationType.byIndex;

  void dispose() {
    elecController.dispose();
    waterController.dispose();
  }
}