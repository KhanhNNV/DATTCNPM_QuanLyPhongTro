import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserProvider {
  // Gọi thông qua ApiClient dùng chung
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/api/users/current');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Không thể lấy thông tin người dùng hiện tại.');
    }
  }
}