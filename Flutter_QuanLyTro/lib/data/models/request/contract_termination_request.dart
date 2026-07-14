class ContractTerminationRequest {
  final int? electricityUsage;
  final int? waterUsage;

  ContractTerminationRequest({
    this.electricityUsage,
    this.waterUsage,
  });

  Map<String, dynamic> toJson() {
    return {
      'electricityUsage': electricityUsage,
      'waterUsage': waterUsage,
    };
  }
}