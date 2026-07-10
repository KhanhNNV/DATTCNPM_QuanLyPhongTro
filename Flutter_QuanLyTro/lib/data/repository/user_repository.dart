import 'dart:convert';
import 'dart:typed_data';
import '../../../core/network/api_client.dart';
import '../models/request/bank_info_update_request.dart';
import '../models/request/user_update_request.dart';
import '../models/response/user_model.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_error_handler.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/api/users/current');

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return UserModel.fromJson(data);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
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
      return utf8.decode(response.bodyBytes);
    }

    // Ném lỗi qua Handler (áp dụng được cho cả phản hồi dạng stream sau khi convert)
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<UserModel> updateUser(String id, UserUpdateRequest request) async {
    final response = await _apiClient.put(
      '/api/users/$id',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return UserModel.fromJson(data);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<String> updateBankInfo(BankInfoUpdateRequest request) async {
    final response = await _apiClient.put(
      '/api/users/profile/bank-info',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}