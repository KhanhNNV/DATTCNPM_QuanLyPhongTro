import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/request/meter_reading_create_request.dart';
import '../models/request/meter_reading_bulk_update_request.dart';
import '../models/response/meter_reading_response.dart';

class MeterReadingProvider {
  final ApiClient _apiClient = ApiClient();

  Future<List<MeterReadingResponse>> createBulkMeterReadings(
      List<MeterReadingCreateRequest> requests) async {
    const String endpoint = '/api/meter-readings/bulk';

    final List<Map<String, dynamic>> body =
    requests.map((req) => req.toJson()).toList();

    final response = await _apiClient.post(endpoint, body);

    if (response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => MeterReadingResponse.fromJson(json)).toList();
    }

    throw Exception('Không thể lưu chỉ số điện/nước hàng loạt: ${response.body}');
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

    throw Exception('Không thể cập nhật chỉ số điện/nước: ${response.body}');
  }
}