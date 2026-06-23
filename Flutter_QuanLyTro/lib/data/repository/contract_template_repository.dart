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

// Bạn có thể bổ sung getTemplates, getTemplateById, updateTemplate, deleteTemplate ở đây
}