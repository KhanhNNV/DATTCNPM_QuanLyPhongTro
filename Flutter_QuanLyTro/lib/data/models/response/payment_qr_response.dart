class PaymentQrResponse {
  final String bankId;
  final String accountNo;
  final String accountName;
  final double amount;
  final String content;
  final String qrImageUrl;

  PaymentQrResponse({
    required this.bankId,
    required this.accountNo,
    required this.accountName,
    required this.amount,
    required this.content,
    required this.qrImageUrl,
  });

  factory PaymentQrResponse.fromJson(Map<String, dynamic> json) {
    return PaymentQrResponse(
      bankId: json['bankId'] ?? '',
      accountNo: json['accountNo'] ?? '',
      accountName: json['accountName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      content: json['content'] ?? '',
      qrImageUrl: json['qrImageUrl'] ?? '',
    );
  }
}