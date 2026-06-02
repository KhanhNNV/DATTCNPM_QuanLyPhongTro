import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/utils/token_manager.dart';

class AuthProvider {
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

      print(data);

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
}