import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/request/contract_template_request.dart';
import '../models/response/contract_template_response.dart';
import '../../../core/utils/api_error_handler.dart'; // Import bộ xử lý lỗi

class ContractTemplateRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ContractTemplateResponse> createTemplate(ContractTemplateRequest request) async {
    final response = await _apiClient.post(
      '/api/contract/templates',
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ContractTemplateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractTemplateResponse> getTemplateById(String id) async {
    final response = await _apiClient.get('/api/contract/templates/$id');

    if (response.statusCode == 200) {
      return ContractTemplateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<List<ContractTemplateResponse>> getAllTemplates() async {
    final response = await _apiClient.get('/api/contract/templates');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => ContractTemplateResponse.fromJson(json)).toList();
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractTemplateResponse> setActiveTemplate(String id) async {
    final response = await _apiClient.put(
      '/api/contract/templates/active/$id',
      {},
    );

    if (response.statusCode == 200) {
      return ContractTemplateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}