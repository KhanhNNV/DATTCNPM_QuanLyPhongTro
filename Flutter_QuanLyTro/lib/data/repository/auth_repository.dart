import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/utils/token_manager.dart';

class AuthRepository {

  // Giải mã JWT Token để đọc dữ liệu (Payload) bên trong
  Map<String, dynamic> _parseJwtPayLoad(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));

    return jsonDecode(resp);
  }

  Future<String> login(String phone, String password, {required String expectedRole}) async {
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
        final payload = _parseJwtPayLoad(accessToken);

        final userRole = payload['role'] ?? payload['roles'] ?? payload['scope'] ?? '';

        final String roleString = userRole.toString().toUpperCase();

        if (!roleString.contains(expectedRole.toUpperCase())) {
          throw Exception('Tài khoản của bạn không có quyền truy cập ứng dụng này!');
        }

        await TokenManager.saveAuthData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: expectedRole,
        );
        return accessToken;
      }
      throw Exception('Token không hợp lệ.');
    } else {
      throw Exception('Tài khoản hoặc mật khẩu không chính xác.');
    }
  }


  Future<String> register(String fullName, String phone, String password, String idCardNumber, String hometown) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/register'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'fullName': fullName,
        'phone': phone,
        'password': password,
        'idCardNumber': idCardNumber,
        'hometown': hometown,
      }),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(response.body);
    }
  }
}