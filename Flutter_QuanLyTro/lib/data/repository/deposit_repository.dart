import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../models/request/deposit_create_request.dart';
import '../models/request/deposit_update_request.dart';
import '../models/response/deposit_response.dart';


class DepositRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<DepositResponse>> getDepositsByAreaId(String areaId) async {
    final response = await _apiClient.get('/api/deposits/area/$areaId');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => DepositResponse.fromJson(json)).toList();
    }
    throw Exception('Không thể tải danh sách phiếu đặt cọc');
  }

  Future<DepositResponse> createDeposit(
      DepositCreateRequest request) async {

    final response = await _apiClient.post(
      '/api/deposits',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return DepositResponse.fromJson(
        jsonDecode(
          utf8.decode(response.bodyBytes),
        ),
      );
    }

    throw Exception(
      'Tạo phiếu đặt cọc thất bại',
    );
  }

  Future<DepositResponse> getDepositById(String depositId) async {
    final response = await _apiClient.get('/api/deposits/$depositId');

    if (response.statusCode == 200) {
      return DepositResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    try {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Không thể tải thông tin chi tiết phiếu cọc');
    } catch (_) {
      throw Exception('Không thể tải thông tin chi tiết phiếu cọc (Mã lỗi: ${response.statusCode})');
    }
  }

  Future<DepositResponse> updateDeposit(String depositId, DepositUpdateRequest request) async {
    final response = await _apiClient.put(
      '/api/deposits/$depositId',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return DepositResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    try {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Cập nhật phiếu đặt cọc thất bại');
    } catch (_) {
      throw Exception('Cập nhật phiếu đặt cọc thất bại (Mã lỗi: ${response.statusCode})');
    }
  }

}