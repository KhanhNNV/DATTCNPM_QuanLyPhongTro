class InvoiceResponse {
  final String id;
  final String roomNumber;
  final String invoicePeriod;
  final String dueDate;
  final double roomPrice;
  final double totalAmount;
  final String status;

  InvoiceResponse({
    required this.id,
    required this.roomNumber,
    required this.invoicePeriod,
    required this.dueDate,
    required this.roomPrice,
    required this.totalAmount,
    required this.status,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceResponse(
      id: json['id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      invoicePeriod: json['invoicePeriod'] ?? '',
      dueDate: json['dueDate'] ?? '',
      roomPrice: (json['roomPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'UNPAID',
    );
  }
}