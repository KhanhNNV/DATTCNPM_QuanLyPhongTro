import 'dart:convert';
import 'dart:io';
import '../../../core/network/api_client.dart';
import '../models/request/contract_create_manual_request.dart';
import '../models/request/contract_create_request.dart';
import '../models/response/contract_create_response.dart';
import '../models/response/contract_detail_response.dart';
import '../../../core/utils/api_error_handler.dart'; // Import bộ xử lý lỗi

class ContractRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ContractCreateResponse> createContractOcr({
    required ContractCreateRequest dataRequest,
    required File frontImage,
    required File backImage,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/contracts/create',
      fields: {
        'data': dataRequest.toJson(),
      },
      files: {
        'frontImage': frontImage,
        'backImage': backImage,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractCreateResponse.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractCreateResponse> createContractManual(ContractCreateManualRequest request) async {
    final response = await _apiClient.post(
      '/api/contracts/create/manual',
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractCreateResponse.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<List<ContractDetailResponse>> getMyContracts() async {
    final response = await _apiClient.get('/api/contracts');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => ContractDetailResponse.fromJson(json)).toList();
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractDetailResponse> getContractDetail(String contractId) async {
    final response = await _apiClient.get('/api/contracts/$contractId');

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractDetailResponse.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractDetailResponse> uploadContractFile(String contractId, File file) async {
    final response = await _apiClient.postMultipart(
      '/api/contracts/upload/file/$contractId',
      fields: {},
      files: {
        'file': file,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractDetailResponse.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}