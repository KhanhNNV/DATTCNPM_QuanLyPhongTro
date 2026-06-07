class RoomModel {
  final String id;
  final String areaName;
  final int floor;
  final String roomNumber;
  final double areaSize;
  final double rentPrice;
  final double depositAmount;
  final int maxOccupants;
  final String status;

  RoomModel({
    required this.id,
    required this.areaName,
    required this.floor,
    required this.roomNumber,
    required this.areaSize,
    required this.rentPrice,
    required this.depositAmount,
    required this.maxOccupants,
    required this.status,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      areaName: json['areaName'] ?? '',
      floor: json['floor'] ?? 0,
      roomNumber: json['roomNumber'] ?? '',
      areaSize: (json['areaSize'] ?? 0).toDouble(),
      rentPrice: (json['rentPrice'] ?? 0).toDouble(),
      depositAmount: (json['depositAmount'] ?? 0).toDouble(),
      maxOccupants: json['maxOccupants'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}