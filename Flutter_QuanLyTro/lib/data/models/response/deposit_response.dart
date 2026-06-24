class DepositResponse {
  final String id;
  final String roomNumber;
  final String tenantFullName;
  final String phone;
  final double depositAmount;
  final String status;
  final String? depositDate;
  final String? expectedMoveInDate;
  final String? note;

  DepositResponse({
    required this.id,
    required this.roomNumber,
    required this.tenantFullName,
    required this.phone,
    required this.depositAmount,
    required this.status,
    this.depositDate,
    this.expectedMoveInDate,
    this.note,
  });

  factory DepositResponse.fromJson(Map<String, dynamic> json) {
    return DepositResponse(
      id: json['id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      tenantFullName: json['tenantFullName'] ?? '',
      phone: json['phone'] ?? '',
      depositAmount: (json['depositAmount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      depositDate: json['depositDate'],
      expectedMoveInDate: json['expectedMoveInDate'],
      note: json['note'],
    );
  }
}