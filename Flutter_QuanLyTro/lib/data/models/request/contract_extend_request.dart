class ContractExtendRequest {
  final String newEndDate; // Format: yyyy-MM-dd

  ContractExtendRequest({required this.newEndDate});

  Map<String, dynamic> toJson() {
    return {
      'newEndDate': newEndDate,
    };
  }
}