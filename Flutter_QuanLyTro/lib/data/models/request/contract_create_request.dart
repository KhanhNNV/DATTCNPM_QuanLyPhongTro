import 'dart:convert';

class ContractCreateRequest {
  final String roomId;
  final String? depositId;
  final String tenantPhone;
  final String templateId;
  final String startDate;
  final String endDate;
  final double depositAmount;

  ContractCreateRequest({
    required this.roomId,
    this.depositId,
    required this.tenantPhone,
    required this.templateId,
    required this.startDate,
    required this.endDate,
    required this.depositAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      if (depositId != null) 'depositId': depositId,
      'tenantPhone': tenantPhone,
      'templateId': templateId,
      'startDate': startDate,
      'endDate': endDate,
      'depositAmount': depositAmount,
    };
  }

  String toJson() => json.encode(toMap());
}