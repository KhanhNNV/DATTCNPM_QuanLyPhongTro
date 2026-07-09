class ContractMemberAddRequest {
  final String contractId;
  final String fullName;
  final String phone;
  final String dob; // Định dạng 'yyyy-MM-dd'
  final String hometown;
  final String idCardNumber;

  ContractMemberAddRequest({
    required this.contractId,
    required this.fullName,
    required this.phone,
    required this.dob,
    required this.hometown,
    required this.idCardNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'fullName': fullName,
      'phone': phone,
      'dob': dob,
      'hometown': hometown,
      'idCardNumber': idCardNumber,
    };
  }
}