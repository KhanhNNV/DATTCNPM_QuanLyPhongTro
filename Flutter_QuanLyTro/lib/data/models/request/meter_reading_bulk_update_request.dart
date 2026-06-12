class MeterReadingBulkUpdateRequest {
  final String id;
  final int newIndex;

  MeterReadingBulkUpdateRequest({
    required this.id,
    required this.newIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'newIndex': newIndex,
    };
  }
}