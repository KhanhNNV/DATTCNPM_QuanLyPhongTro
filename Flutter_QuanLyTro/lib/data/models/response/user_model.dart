class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String role;
  final String? dob;
  final String? hometown;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.dob,
    this.hometown,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? 'Chưa cập nhật',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      dob: json['dob'],
      hometown: json['hometown'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'dob': dob,
      'hometown': hometown,
    };
  }
}