class DepositCreateRequest {
  final String roomId;
  final String phone;
  final String tenantFullName;
  final double depositAmount;
  final String expectedMoveInDate;
  final String? note;

  DepositCreateRequest({
    required this.roomId,
    required this.phone,
    required this.tenantFullName,
    required this.depositAmount,
    required this.expectedMoveInDate,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      "roomId": roomId,
      "phone": phone,
      "tenantFullName": tenantFullName,
      "depositAmount": depositAmount,
      "expectedMoveInDate": expectedMoveInDate,
      "note": note,
    };
  }
}