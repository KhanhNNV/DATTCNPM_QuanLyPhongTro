class ContractTemplateRequest {
  final String name;
  final String rentalContent;
  final String landlordDuty;
  final String tenantDuty;
  final String executionTerms;

  ContractTemplateRequest({
    required this.name,
    required this.rentalContent,
    required this.landlordDuty,
    required this.tenantDuty,
    required this.executionTerms,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "rentalContent": rentalContent,
      "landlordDuty": landlordDuty,
      "tenantDuty": tenantDuty,
      "executionTerms": executionTerms,
    };
  }
}