import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/utils/token_manager.dart';

class AuthRepository {
  Future<String> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];


      if (accessToken != null) {
        await TokenManager.saveAuthData(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return accessToken;
      }
      throw Exception('Token không hợp lệ.');
    } else {
      throw Exception('Tài khoản hoặc mật khẩu không chính xác.');
    }
  }

  Future<String> register(String fullName, String phone, String password) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/register'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'fullName': fullName,
        'phone': phone,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(response.body);
    }
  }
}