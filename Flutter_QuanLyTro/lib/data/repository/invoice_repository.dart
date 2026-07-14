import 'dart:convert';
import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../core/utils/api_error_handler.dart';
import '../models/response/invoice_response.dart';
import '../models/response/invoice_detail_response.dart';
import '../models/response/payment_qr_response.dart';

class InvoiceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getAllInvoicesForLandlord({
    int page = 0,
    int size = 10,
    String? status,
    String? areaId,
  }) async {
    // Xây dựng query parameters
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (status != null && status != 'ALL') {
      queryParams['status'] = status;
    }

    // 🎯 SỬA Ở ĐÂY: Thêm areaId vào query parameters nếu có giá trị
    if (areaId != null && areaId.isNotEmpty && areaId != 'ALL') {
      queryParams['areaId'] = areaId;
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

  Future<Map<String, dynamic>> getMyInvoices({
    int page = 0,
    int size = 10,
    String? status,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (status != null && status != 'ALL') {
      queryParams['status'] = status;
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '/api/invoices/tenant?$queryString';

    final response = await _apiClient.get(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));

      final List<dynamic> content = responseData['content'] ?? responseData['data'] ?? [];
      final List<InvoiceResponse> invoices = content.map((json) => InvoiceResponse.fromJson(json)).toList();

      final int totalPages = responseData['totalPages'] ?? 1;

      return {
        'invoices': invoices,
        'totalPages': totalPages,
      };
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<PaymentQrResponse> getPaymentQrCode(String id) async {
    final response = await _apiClient.get('/api/invoices/$id/qr-code');
    if (response.statusCode == 200) {
      return PaymentQrResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> uploadPaymentProof(String id, File file) async {
    final path = '/api/invoices/$id/upload-proof';

    final response = await _apiClient.postMultipart(
      path,
      fields: {},
      files: {
        'file': file,
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> confirmPayment(String id) async {
    final response = await _apiClient.put('/api/invoices/$id/confirm-payment',{});

    if (response.statusCode != 200) {
      final rawError = utf8.decode(response.bodyBytes);
      throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
    }
  }

  Future<void> rejectPayment(String id, String reason) async {
    final uri = Uri(
      path: '/api/invoices/$id/reject-payment',
      queryParameters: {'reason': reason},
    );

    final response = await _apiClient.put(uri.toString(),{});

    if (response.statusCode != 200) {
      final rawError = utf8.decode(response.bodyBytes);
      throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
    }
  }
}