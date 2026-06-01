import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/utils/token_manager.dart';

class AuthProvider {
  // API Đăng nhập (Lúc này chưa có token nên gọi thẳng http.post)
  Future<String> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['accessToken'];

      if (token != null) {
        // LƯU VÀO ĐÂY: Kể từ giây phút này, ApiClient sẽ tự động có token để dùng
        TokenManager.saveToken(token);
        return token;
      }
      throw Exception('Token không hợp lệ.');
    } else {
      throw Exception('Tài khoản hoặc mật khẩu không chính xác.');
    }
  }
}