import 'dart:convert';
import '../../../core/network/api_client.dart';

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
}