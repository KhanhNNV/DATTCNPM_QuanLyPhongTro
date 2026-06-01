class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
  });


  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? 'Người dùng',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
    );
  }
}