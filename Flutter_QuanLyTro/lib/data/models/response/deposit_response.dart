class DepositResponse {
  final String id;
  final String roomNumber;
  final String tenantFullName;
  final String phone;
  final double depositAmount;
  final String status;

  DepositResponse({
    required this.id,
    required this.roomNumber,
    required this.tenantFullName,
    required this.phone,
    required this.depositAmount,
    required this.status,
  });

  factory DepositResponse.fromJson(
      Map<String, dynamic> json) {
    return DepositResponse(
      id: json['id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      tenantFullName:
      json['tenantFullName'] ?? '',
      phone: json['phone'] ?? '',
      depositAmount:
      (json['depositAmount'] ?? 0)
          .toDouble(),
      status: json['status'] ?? '',
    );
  }
}