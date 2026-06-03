import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../models/area_model.dart';

class AreaProvider {
  final ApiClient _apiClient = ApiClient();

  Future<void> onboardNewLandlord(Map<String, dynamic> requestData) async {
    final response = await _apiClient.post('/api/areas/onboarding', requestData);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    } else {
      throw Exception('Lỗi khởi tạo khu trọ: ${response.body}');
    }
  }

  //Lấy area của chủ trọ hiện tại
  Future<List<AreaModel>> getAreasByLandlord() async {
    final response = await _apiClient.get('/api/areas');
    if (response.statusCode == 200) {
      final List<dynamic> decodedData = jsonDecode(utf8.decode(response.bodyBytes));
      return decodedData.map((json) => AreaModel.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải danh sách khu trọ: ${response.body}');
    }
  }
}