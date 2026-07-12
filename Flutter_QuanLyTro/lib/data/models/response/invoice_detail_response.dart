import 'invoice_item_response.dart';

class InvoiceDetailResponse {
  final String id;
  final String roomNumber;
  final String invoicePeriod;
  final String dueDate;
  final double roomPrice;
  final double totalAmount;
  final String status;
  final List<InvoiceItemResponse> items;

  InvoiceDetailResponse({
    required this.id,
    required this.roomNumber,
    required this.invoicePeriod,
    required this.dueDate,
    required this.roomPrice,
    required this.totalAmount,
    required this.status,
    required this.items,
  });

  factory InvoiceDetailResponse.fromJson(Map<String, dynamic> json) {
    var itemsList = (json['items'] as List? ?? [])
        .map((i) => InvoiceItemResponse.fromJson(i))
        .toList();

    return InvoiceDetailResponse(
      id: json['id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      invoicePeriod: json['invoicePeriod'] ?? '',
      dueDate: json['dueDate'] ?? '',
      roomPrice: (json['roomPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'UNPAID',
      items: itemsList,
    );
  }
}