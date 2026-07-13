class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String role;
  final String? dob;
  final String? hometown;
  final String? idCardNumber;
  final bool? isFirstLogin;
  final String? bankId;
  final String? accountNo;
  final String? accountName;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.dob,
    this.hometown,
    this.idCardNumber,
    this.isFirstLogin,
    this.bankId,
    this.accountNo,
    this.accountName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? 'Chưa cập nhật',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      dob: json['dob'],
      hometown: json['hometown'],
      idCardNumber: json['idCardNumber'],
      isFirstLogin: json['isFirstLogin'],
      bankId: json['bankId'],
      accountNo: json['accountNo'],
      accountName: json['accountName'],
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
      'idCardNumber': idCardNumber,
      'isFirstLogin': isFirstLogin,
      'bankId': bankId,
      'accountNo': accountNo,
      'accountName': accountName,
    };
  }
}