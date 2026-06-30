import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/request/contract_template_request.dart';
import '../models/response/contract_template_response.dart';

class ContractTemplateRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ContractTemplateResponse> createTemplate(ContractTemplateRequest request) async {
    final response = await _apiClient.post(
      '/api/contract/templates',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return ContractTemplateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    try {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Tạo mẫu hợp đồng thất bại');
    } catch (_) {
      throw Exception('Tạo mẫu hợp đồng thất bại (Mã lỗi: ${response.statusCode})');
    }
  }

  Future<ContractTemplateResponse> getTemplateById(String id) async {
    final response = await _apiClient.get('/api/contract/templates/$id');

    if (response.statusCode == 200) {
      return ContractTemplateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    _handleError(response);
    throw Exception('Không thể lấy thông tin mẫu hợp đồng');
  }

  Future<List<ContractTemplateResponse>> getAllTemplates() async {
    final response = await _apiClient.get('/api/contract/templates');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => ContractTemplateResponse.fromJson(json)).toList();
    }

    _handleError(response);
    return []; // Dummy return
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

    _handleError(response);
    throw Exception('Cập nhật mẫu mặc định thất bại');
  }

  void _handleError(dynamic response) {
    try {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (_) {
      throw Exception('Lỗi xử lý hệ thống (Mã lỗi: ${response.statusCode})');
    }
  }
}