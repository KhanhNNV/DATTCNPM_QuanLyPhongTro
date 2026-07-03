import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../core/utils/api_error_handler.dart';
import '../models/request/deposit_create_request.dart';
import '../models/request/deposit_update_request.dart';
import '../models/response/deposit_response.dart';


class DepositRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<DepositResponse>> getDepositsByAreaId(String areaId, {String? status}) async {
    String url = '/api/deposits/area/$areaId';

    if (status != null && status.isNotEmpty && status != 'ALL') {
      url += '?status=$status';
    }

    final response = await _apiClient.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => DepositResponse.fromJson(json)).toList();
    }
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
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

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<DepositResponse> getDepositById(String depositId) async {
    final response = await _apiClient.get('/api/deposits/$depositId');

    if (response.statusCode == 200) {
      return DepositResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
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

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

}