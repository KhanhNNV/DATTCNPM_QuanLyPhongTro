import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../core/utils/api_error_handler.dart';
import '../models/response/invoice_response.dart';

class InvoiceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<InvoiceResponse>> getAllInvoicesForLandlord() async {
    final response = await _apiClient.get('/api/invoices/landlord');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => InvoiceResponse.fromJson(json)).toList();
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}