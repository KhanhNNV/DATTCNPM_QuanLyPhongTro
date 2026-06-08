import 'dart:convert';
import 'dart:typed_data';
import '../../../core/network/api_client.dart';
import '../models/response/user_model.dart';
import 'package:http/http.dart' as http;

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

  Future<String> updateSignature(Uint8List imageBytes) async {
    final streamedResponse = await _apiClient.putMultipart(
        '/api/users/signature',
        'file',
        imageBytes,
        'signature.png'
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(
          response.body.isNotEmpty
              ? response.body
              : 'Cập nhật chữ ký thất bại. Mã lỗi: ${response.statusCode}'
      );
    }
  }
}