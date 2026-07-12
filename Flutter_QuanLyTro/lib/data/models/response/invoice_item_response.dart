class InvoiceItemResponse {
  final String serviceName;
  final int? oldIndex;
  final int? newIndex;
  final int quantity;
  final double price;
  final double totalAmount;

  InvoiceItemResponse({
    required this.serviceName,
    this.oldIndex,
    this.newIndex,
    required this.quantity,
    required this.price,
    required this.totalAmount,
  });

  factory InvoiceItemResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceItemResponse(
      serviceName: json['serviceName'] ?? '',
      oldIndex: json['oldIndex'],
      newIndex: json['newIndex'],
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}