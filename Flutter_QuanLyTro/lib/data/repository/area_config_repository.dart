import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_error_handler.dart';
class AreaConfigRepository {
  final ApiClient _apiClient = ApiClient();

  // ==========================================
  // API QUẢN LÝ DỊCH VỤ
  // ==========================================

  Future<List<dynamic>> getServicesByArea(String areaId) async {
    final response = await _apiClient.get('/api/area-services/area/$areaId');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> createService(String areaId, Map<String, dynamic> body) async {
    final response = await _apiClient.post('/api/area-services/area/$areaId', body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> body) async {
    final response = await _apiClient.put('/api/area-services/$serviceId', body);
    if (response.statusCode == 200) {
      return;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  // ==========================================
  // API QUẢN LÝ PHÒNG TRỌ
  // ==========================================

  Future<List<dynamic>> getRoomsByArea(String areaId) async {
    final response = await _apiClient.get('/api/rooms/area/$areaId');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> createRoom(Map<String, dynamic> body) async {
    final response = await _apiClient.post('/api/rooms', body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> body) async {
    final response = await _apiClient.put('/api/rooms/$roomId', body);
    if (response.statusCode == 200) {
      return;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> deleteRoom(String roomId) async {
    final response = await _apiClient.delete('/api/rooms/$roomId');
    if (response.statusCode == 200) {
      return;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}