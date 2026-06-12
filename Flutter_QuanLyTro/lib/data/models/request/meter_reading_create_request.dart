class MeterReadingCreateRequest {
  final String roomId;
  final String serviceId;
  final int newIndex;
  final String readingDate;

  MeterReadingCreateRequest({
    required this.roomId,
    required this.serviceId,
    required this.newIndex,
    required this.readingDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'serviceId': serviceId,
      'newIndex': newIndex,
      'readingDate': readingDate,
    };
  }
}