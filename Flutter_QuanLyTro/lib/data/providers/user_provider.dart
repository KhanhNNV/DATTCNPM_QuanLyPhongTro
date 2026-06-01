import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserProvider {
  // Gọi thông qua ApiClient dùng chung
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> getCurrentUser() async {
    // Token đã tự động được kẹp ngầm bên trong hàm get() rồi
    final response = await _apiClient.get('/users/me');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Không thể lấy thông tin người dùng hiện tại.');
    }
  }
}