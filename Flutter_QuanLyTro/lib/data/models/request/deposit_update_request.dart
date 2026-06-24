class DepositUpdateRequest {
  final String phone;
  final String tenantFullName;
  final double depositAmount;
  final String expectedMoveInDate;
  final String? note;
  final String status;

  DepositUpdateRequest({
    required this.phone,
    required this.tenantFullName,
    required this.depositAmount,
    required this.expectedMoveInDate,
    this.note,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'tenantFullName': tenantFullName,
      'depositAmount': depositAmount,
      'expectedMoveInDate': expectedMoveInDate,
      'note': note,
      'status': status,
    };
  }
}