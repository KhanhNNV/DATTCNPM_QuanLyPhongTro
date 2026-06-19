import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../models/request/deposit_create_request.dart';
import '../models/response/deposit_response.dart';


class DepositRepository {
  final ApiClient _apiClient = ApiClient();

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
}