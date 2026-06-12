class MeterReadingResponse {
  final String id;
  final String roomNumber;
  final String serviceName;
  final int oldIndex;
  final int newIndex;
  final String readingDate;
  final bool isInvoiced;

  MeterReadingResponse({
    required this.id,
    required this.roomNumber,
    required this.serviceName,
    required this.oldIndex,
    required this.newIndex,
    required this.readingDate,
    required this.isInvoiced,
  });

  factory MeterReadingResponse.fromJson(Map<String, dynamic> json) {
    return MeterReadingResponse(
      id: json['id'] as String,
      roomNumber: json['roomNumber'] as String,
      serviceName: json['serviceName'] as String,
      oldIndex: json['oldIndex'] as int,
      newIndex: json['newIndex'] as int,
      readingDate: json['readingDate'] as String,
      isInvoiced: json['isInvoiced'] as bool,
    );
  }
}