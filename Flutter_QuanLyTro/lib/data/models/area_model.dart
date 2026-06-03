class AreaModel {
  final String name;
  final String address;
  final int invoiceDay;
  final int dueDate;
  final DateTime? createdAt;

  AreaModel({
    required this.name,
    required this.address,
    required this.invoiceDay,
    required this.dueDate,
    this.createdAt,
  });

  // Hàm chuyển đổi từ JSON sang Object
  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      invoiceDay: json['invoiceDay'] ?? 0,
      dueDate: json['dueDate'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}