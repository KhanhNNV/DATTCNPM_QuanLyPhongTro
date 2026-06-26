class ContractTemplateResponse {
  final String id;
  final String name;
  final String rentalContent;
  final String landlordDuty;
  final String tenantDuty;
  final String executionTerms;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  ContractTemplateResponse({
    required this.id,
    required this.name,
    required this.rentalContent,
    required this.landlordDuty,
    required this.tenantDuty,
    required this.executionTerms,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ContractTemplateResponse.fromJson(Map<String, dynamic> json) {
    return ContractTemplateResponse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rentalContent: json['rentalContent'] ?? '',
      landlordDuty: json['landlordDuty'] ?? '',
      tenantDuty: json['tenantDuty'] ?? '',
      executionTerms: json['executionTerms'] ?? '',
      isActive: json['isActive'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}