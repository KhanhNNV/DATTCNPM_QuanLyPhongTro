class ContractMemberResponse {
  final String id;
  final String fullName;
  final String? phone;

  ContractMemberResponse({
    required this.id,
    required this.fullName,
    this.phone,
  });

  factory ContractMemberResponse.fromJson(Map<String, dynamic> json) {
    return ContractMemberResponse(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
    );
  }
}