import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_manager.dart';

class ApiClient {
  // Cấu hình IP Backend dùng chung cho toàn bộ App
  static const String baseUrl = 'http://localhost:8080';

  // Hàm helper để tự động tạo Header chứa Token
  Map<String, String> _getHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token', // Tự động kẹp Token vào đây
    };
  }

  // --- TỰ ĐỘNG KẸP TOKEN CHO HÀM GET ---
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: _getHeaders());
  }

  // --- TỰ ĐỘNG KẸP TOKEN CHO HÀM POST ---
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
  }

// Bạn có thể viết thêm hàm put(), delete() tương tự tại đây...
}