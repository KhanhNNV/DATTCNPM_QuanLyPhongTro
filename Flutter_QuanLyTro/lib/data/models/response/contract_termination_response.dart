class ContractTerminationResponse {
  final String contractId;
  final String roomNumber;
  final double depositAmount;
  final double totalDeduction;
  final double finalAmount;
  final String settlementAction;
  final String message;

  ContractTerminationResponse({
    required this.contractId,
    required this.roomNumber,
    required this.depositAmount,
    required this.totalDeduction,
    required this.finalAmount,
    required this.settlementAction,
    required this.message,
  });

  factory ContractTerminationResponse.fromJson(Map<String, dynamic> json) {
    return ContractTerminationResponse(
      contractId: json['contractId'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      depositAmount: (json['depositAmount'] ?? 0).toDouble(),
      totalDeduction: (json['totalDeduction'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      settlementAction: json['settlementAction'] ?? '',
      message: json['message'] ?? '',
    );
  }
}