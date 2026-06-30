import 'dart:convert';
import 'dart:io';
import '../../../core/network/api_client.dart';
import '../models/request/contract_create_manual_request.dart';
import '../models/request/contract_create_request.dart';
import '../models/response/contract_create_response.dart';
import '../models/response/contract_detail_response.dart';

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

    throw Exception('Quá trình lập hợp đồng thất bại: ${response.body}');
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

    throw Exception('Quá trình lập hợp đồng thủ công thất bại: ${response.body}');
  }

  Future<List<ContractDetailResponse>> getMyContracts() async {
    final response = await _apiClient.get('/api/contracts');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => ContractDetailResponse.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải danh sách hợp đồng từ hệ thống!');
    }
  }

  Future<ContractDetailResponse> getContractDetail(String contractId) async {
    final response = await _apiClient.get('/api/contracts/$contractId');

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractDetailResponse.fromJson(json);
    }

    throw Exception('Không thể tải thông tin chi tiết hợp đồng!');
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

    throw Exception('Lỗi tải file đính kèm hợp đồng lên: ${response.body}');
  }
}