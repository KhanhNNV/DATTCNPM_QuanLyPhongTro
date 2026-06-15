class MeterReadingResponse {
  final String? id;
  final String roomNumber;
  final String serviceName;
  final int oldIndex;
  final int newIndex;
  final String readingDate;
  final bool isInvoiced;
  final String? serviceId;

  MeterReadingResponse({
    this.id,
    required this.roomNumber,
    required this.serviceName,
    required this.oldIndex,
    required this.newIndex,
    required this.readingDate,
    required this.isInvoiced,
    this.serviceId,
  });

  factory MeterReadingResponse.fromJson(Map<String, dynamic> json) {
    return MeterReadingResponse(
      id: json['id'] as String?,
      roomNumber: json['roomNumber'] ?? '',
      serviceName: json['serviceName'] ?? '',
      oldIndex: json['oldIndex'] ?? 0,
      newIndex: json['newIndex'] ?? 0,
      readingDate: json['readingDate'] ?? '',
      isInvoiced: json['isInvoiced'] ?? false,
      serviceId: json['serviceId'] as String?,
    );
  }
}