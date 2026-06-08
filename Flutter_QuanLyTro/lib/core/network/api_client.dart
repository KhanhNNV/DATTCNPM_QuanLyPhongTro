import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../features/landlord_app/welcome/welcome_screen.dart';
import '../../main.dart';
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

  // xử lý refreshToken
  Future<bool> _refreshToken() async {
    try {
      // Lấy Refresh Token đang lưu trong máy
      final currentRefreshToken = await TokenManager.getRefreshToken();

      if (currentRefreshToken == null) {
        return false;
      }

      // Gọi API /refresh của Backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': currentRefreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Lưu Access Token mới và Refresh Token mới
        await TokenManager.saveAuthData(
          accessToken: data['accessToken'],
          refreshToken:
              data['refreshToken'] ??
              currentRefreshToken, // Nếu backend ko cấp refresh mới thì xài lại cái cũ
        );
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders();

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 401) {
      bool isRefreshed = await _refreshToken();

      if (isRefreshed) {
        // Lấy header mới và gọi lại api lần 2
        headers = await _getHeaders();
        response = await http.get(url, headers: headers);
      } else {
        // Xóa dữ liệu để app văng ra Login
        await TokenManager.clearAuthData();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) =>
              false, // Xóa sạch lịch sử các trang trước đó, không cho bấm back quay lại
        );
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
    }

    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders();
    final jsonBody = jsonEncode(body);

    var response = await http.post(url, headers: headers, body: jsonBody);

    if (response.statusCode == 401 || response.statusCode == 403) {
      bool isRefreshed = await _refreshToken();
      if (isRefreshed) {
        headers = await _getHeaders(); // Lấy token mới
        response = await http.post(
          url,
          headers: headers,
          body: jsonBody,
        ); // Gọi lại lần 2
      } else {
        await TokenManager.clearAuthData();
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
    }

    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders();
    final jsonBody = jsonEncode(body);

    var response = await http.put(url, headers: headers, body: jsonBody);

    if (response.statusCode == 401 || response.statusCode == 403) {
      bool isRefreshed = await _refreshToken();

      if (isRefreshed) {
        headers = await _getHeaders();

        response = await http.put(url, headers: headers, body: jsonBody);
      } else {
        await TokenManager.clearAuthData();

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );

        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
    }

    return response;
  }


  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders();

    var response = await http.delete(url, headers: headers);
    if (response.statusCode == 401 || response.statusCode == 403) {
      bool isRefreshed = await _refreshToken();

      if (isRefreshed) {
        headers = await _getHeaders();
        response = await http.delete(url, headers: headers);
      } else {
        await TokenManager.clearAuthData();

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
        );

        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
    }

    return response;
  }

  // Hàm xử lý upload file (PUT)
  Future<http.StreamedResponse> putMultipart(
      String endpoint,
      String fileField,
      Uint8List fileBytes,
      String fileName
      ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var request = http.MultipartRequest('PUT', url);

    // Lấy Token gắn vào header
    final token = await TokenManager.getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Gắn file vào request
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
      ),
    );

    var streamedResponse = await request.send();

    // Xử lý logic Refresh Token nếu bị lỗi 401/403
    if (streamedResponse.statusCode == 401 || streamedResponse.statusCode == 403) {
      bool isRefreshed = await _refreshToken();

      if (isRefreshed) {
        // Tạo lại request mới sau khi có token mới
        request = http.MultipartRequest('PUT', url);
        final newToken = await TokenManager.getAccessToken();
        request.headers['Authorization'] = 'Bearer $newToken';
        request.files.add(
          http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName),
        );
        streamedResponse = await request.send();
      } else {
        await TokenManager.clearAuthData();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
        );
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
    }

    return streamedResponse;
  }
}
