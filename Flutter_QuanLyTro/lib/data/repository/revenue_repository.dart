import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../core/utils/api_error_handler.dart';
import '../models/response/revenue_report_response.dart';

class RevenueRepository {
  final ApiClient _apiClient = ApiClient();

  Future<RevenueReportResponse> getRevenueReport({
    required String month, // Định dạng YYYY-MM-DD nhận từ ViewModel
    String? areaId,
  }) async {
    String path = '/api/revenue/report?month=$month';

    if (areaId != null && areaId.isNotEmpty && areaId != 'ALL') {
      path += '&areaId=$areaId';
    }

    final response = await _apiClient.get(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return RevenueReportResponse.fromJson(responseData);
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}