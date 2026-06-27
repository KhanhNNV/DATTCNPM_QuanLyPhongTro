import 'dart:convert';

class ContractCreateManualRequest {
  final String roomId;
  final String startDate;
  final String endDate;
  final double depositAmount;
  final String? depositId;

  final String tenantName;
  final String tenantPhone;
  final String tenantDob;
  final String tenantHometown;
  final String tenantIdCardNumber;

  ContractCreateManualRequest({
    required this.roomId,
    required this.startDate,
    required this.endDate,
    required this.depositAmount,
    this.depositId,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantDob,
    required this.tenantHometown,
    required this.tenantIdCardNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'startDate': startDate,
      'endDate': endDate,
      'depositAmount': depositAmount,
      if (depositId != null) 'depositId': depositId,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'tenantDob': tenantDob,
      'tenantHometown': tenantHometown,
      'tenantIdCardNumber': tenantIdCardNumber,
    };
  }

  String toJson() => json.encode(toMap());
}