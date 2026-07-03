import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/request/meter_reading_create_request.dart';
import '../models/request/meter_reading_bulk_update_request.dart';
import '../models/response/meter_reading_response.dart';
import '../../../core/utils/api_error_handler.dart'; // Import bộ xử lý lỗi

class MeterReadingRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<MeterReadingResponse>> getMeterReadings(String roomId, DateTime month) async {
    final String formattedDate = "${month.year}-${month.month.toString().padLeft(2, '0')}-01";
    final String endpoint = '/api/meter-readings?roomId=$roomId&month=$formattedDate';

    final response = await _apiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => MeterReadingResponse.fromJson(json)).toList();
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<List<MeterReadingResponse>> createBulkMeterReadings(
      List<MeterReadingCreateRequest> requests) async {
    const String endpoint = '/api/meter-readings/bulk';

    final List<Map<String, dynamic>> body =
    requests.map((req) => req.toJson()).toList();

    final response = await _apiClient.post(endpoint, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => MeterReadingResponse.fromJson(json)).toList();
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<List<MeterReadingResponse>> updateBulkMeterReadings(
      List<MeterReadingBulkUpdateRequest> requests) async {
    const String endpoint = '/api/meter-readings/bulk';

    final List<Map<String, dynamic>> body =
    requests.map((req) => req.toJson()).toList();

    final response = await _apiClient.put(endpoint, body);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => MeterReadingResponse.fromJson(json)).toList();
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}