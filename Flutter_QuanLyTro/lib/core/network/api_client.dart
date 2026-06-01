import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_manager.dart';

class ApiClient {
  // Cấu hình IP Backend dùng chung cho toàn bộ App
  static const String baseUrl = 'http://192.168.0.197:8080';

  // Hàm helper để tự động tạo Header chứa Token
  // Hàm này biến thành async
  Future<Map<String, String>> _getHeaders() async {
    // Thêm await ở đây
    final token = await TokenManager.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Cập nhật lại các hàm get/post để đợi _getHeaders()
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(); // Thêm await
    return await http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(); // Thêm await
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

// Bạn có thể viết thêm hàm put(), delete() tương tự tại đây...
}