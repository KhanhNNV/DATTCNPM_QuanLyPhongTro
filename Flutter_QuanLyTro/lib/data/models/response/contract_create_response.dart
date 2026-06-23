class ContractCreateResponse {
  final String contractId;
  final String tenantUsername;
  final String tenantRawPassword;
  final String message;

  ContractCreateResponse({
    required this.contractId,
    required this.tenantUsername,
    required this.tenantRawPassword,
    required this.message,
  });

  factory ContractCreateResponse.fromJson(Map<String, dynamic> json) {
    return ContractCreateResponse(
      contractId: json['contractId'] ?? '',
      tenantUsername: json['tenantUsername'] ?? '',
      tenantRawPassword: json['tenantRawPassword'] ?? '',
      message: json['message'] ?? '',
    );
  }
}