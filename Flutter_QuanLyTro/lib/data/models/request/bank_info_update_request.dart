class BankInfoUpdateRequest {
  final String? bankId;
  final String? accountNo;
  final String? accountName;

  BankInfoUpdateRequest({
    this.bankId,
    this.accountNo,
    this.accountName,
  });

  Map<String, dynamic> toJson() {
    return {
      'bankId': bankId,
      'accountNo': accountNo,
      'accountName': accountName,
    };
  }
}