import 'package:flutter/material.dart';

enum ServiceCalculationType { byIndex, perPerson, perRoom }

extension ServiceCalculationTypeExt on ServiceCalculationType {
  String get backendValue {
    switch (this) {
      case ServiceCalculationType.byIndex: return 'BY_INDEX';
      case ServiceCalculationType.perPerson: return 'PER_PERSON';
      case ServiceCalculationType.perRoom: return 'PER_ROOM';
    }
  }

  String get label {
    switch (this) {
      case ServiceCalculationType.byIndex: return 'Theo chỉ số';
      case ServiceCalculationType.perPerson: return 'Theo người';
      case ServiceCalculationType.perRoom: return 'Theo phòng';
    }
  }

  String getUnit(String serviceName) {
    if (this == ServiceCalculationType.byIndex) {
      if (serviceName.toLowerCase() == 'điện') return 'VNĐ/kWh';
      if (serviceName.toLowerCase() == 'nước') return 'VNĐ/khối';
      return 'VNĐ/đơn vị';
    } else if (this == ServiceCalculationType.perPerson) {
      return 'VNĐ/người';
    } else {
      return 'VNĐ/phòng';
    }
  }
}

class AppServiceItem {
  String name;
  ServiceCalculationType calcType;
  TextEditingController priceController;

  AppServiceItem({
    required this.name,
    required this.calcType,
  }) : priceController = TextEditingController();
}