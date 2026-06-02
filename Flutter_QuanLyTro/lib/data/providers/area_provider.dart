import 'dart:convert';
import '../../../core/network/api_client.dart';

class AreaProvider {
  final ApiClient _apiClient = ApiClient();

  Future<void> onboardNewLandlord(Map<String, dynamic> requestData) async {
    // Gọi API POST. ApiClient đã tự động kẹp Token vào Header rồi.
    // Lưu ý: Đảm bảo endpoint khớp với ApiClient.baseUrl của bạn (vd: '/areas/onboarding')
    final response = await _apiClient.post('/areas/onboarding', requestData);

    // Backend đang trả về HttpStatus.CREATED (201)
    if (response.statusCode == 201 || response.statusCode == 200) {
      return; // Thành công
    } else {
      // Có lỗi từ Backend (vd: thiếu dữ liệu, sai format...)
      throw Exception('Lỗi khởi tạo khu trọ: ${response.body}');
    }
  }
}