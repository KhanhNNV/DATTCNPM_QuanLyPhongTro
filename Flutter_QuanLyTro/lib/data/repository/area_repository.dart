import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/response/area_model.dart';
import '../../../core/utils/api_error_handler.dart';

class AreaRepository {
  final ApiClient _apiClient = ApiClient();

  Future<AreaModel> onboardNewLandlord(Map<String, dynamic> requestData) async {
    final response = await _apiClient.post(
      '/api/areas/onboarding',
      requestData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return AreaModel.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  // Lấy area của chủ trọ hiện tại
  Future<List<AreaModel>> getAreasByLandlord() async {
    final response = await _apiClient.get('/api/areas');

    if (response.statusCode == 200) {
      final List<dynamic> decodedData = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      return decodedData.map((json) => AreaModel.fromJson(json)).toList();
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> updateArea(String areaId, Map<String, dynamic> payload) async {
    final response = await _apiClient.put('/api/areas/$areaId', payload);

    if (response.statusCode == 200) {
      return; // Thành công
    }

    // Ném lỗi qua Handler (Bổ sung thêm catch lỗi cho hàm update)
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<AreaModel> getAreaById(String areaId) async {
    final response = await _apiClient.get('/api/areas/$areaId');

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return AreaModel.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}