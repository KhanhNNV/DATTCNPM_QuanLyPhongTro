import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../core/utils/api_error_handler.dart';
import '../models/response/invoice_response.dart';
import '../models/response/invoice_detail_response.dart';

class InvoiceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getAllInvoicesForLandlord({
    int page = 0,
    int size = 10,
    String? status,
  }) async {
    // Xây dựng query parameters
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (status != null && status != 'ALL') {
      queryParams['status'] = status;
    }

    // Ghép query string vào path
    final queryString = Uri(queryParameters: queryParams).query;
    final path = '/api/invoices/landlord?$queryString';

    final response = await _apiClient.get(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));

      // Lấy danh sách
      final List<dynamic> content = responseData['content'] ?? responseData['data'] ?? [];
      final List<InvoiceResponse> invoices = content.map((json) => InvoiceResponse.fromJson(json)).toList();

      // Lấy tổng số trang
      final int totalPages = responseData['totalPages'] ?? 1;

      return {
        'invoices': invoices,
        'totalPages': totalPages,
      };
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
  
  Future<InvoiceDetailResponse> getInvoiceDetail(String id) async {
    final response = await _apiClient.get('/api/invoices/$id');
    if (response.statusCode == 200) {
      return InvoiceDetailResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes))
      );
    }
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}