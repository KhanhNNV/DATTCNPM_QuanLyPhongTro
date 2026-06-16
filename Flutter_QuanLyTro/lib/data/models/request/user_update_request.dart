class UserUpdateRequest {
  final String phone;
  final String? password;
  final String fullName;
  final String dob;
  final String hometown;

  UserUpdateRequest({
    required this.phone,
    this.password,
    required this.fullName,
    required this.dob,
    required this.hometown,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'phone': phone,
      'fullName': fullName,
      'dob': dob,
      'hometown': hometown,
    };

    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }

    return data;
  }
}