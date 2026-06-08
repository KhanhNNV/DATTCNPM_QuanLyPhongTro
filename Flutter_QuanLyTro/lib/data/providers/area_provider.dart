import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/response/area_model.dart';

class AreaProvider {
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
    throw Exception('Lỗi khởi tạo khu trọ: ${response.body}');
  }

  //Lấy area của chủ trọ hiện tại
  Future<List<AreaModel>> getAreasByLandlord() async {
    final response = await _apiClient.get('/api/areas');
    if (response.statusCode == 200) {
      final List<dynamic> decodedData = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      return decodedData.map((json) => AreaModel.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải danh sách khu trọ: ${response.body}');
    }
  }

  Future<void> updateArea(String areaId, Map<String, dynamic> payload) async {
    await _apiClient.put('/api/areas/$areaId', payload);
  }
}
