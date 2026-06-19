import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';

class AreaConfigRepository {
  final ApiClient _apiClient = ApiClient();

  // API QUẢN LÝ DỊCH VỤ
  Future<List<dynamic>> getServicesByArea(String areaId) async {
    final response = await _apiClient.get('/api/area-services/area/$areaId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Không thể tải danh sách dịch vụ của khu trọ.');
  }

  Future<void> createService(String areaId, Map<String, dynamic> body) async {
    final response = await _apiClient.post('/api/area-services/area/$areaId', body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Thêm dịch vụ mới thất bại: ${response.body}');
    }
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> body) async {
    final response = await _apiClient.put('/api/area-services/$serviceId', body);
    if (response.statusCode != 200) {
      throw Exception('Cập nhật dịch vụ thất bại: ${response.body}');
    }
  }

  // API QUẢN LÝ PHÒNG TRỌ
  Future<List<dynamic>> getRoomsByArea(String areaId) async {
    final response = await _apiClient.get('/api/rooms/area/$areaId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Không thể tải danh sách phòng trọ.');
  }

  Future<void> createRoom(Map<String, dynamic> body) async {
    final response = await _apiClient.post('/api/rooms', body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Tạo phòng mới thất bại: ${response.body}');
    }
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> body) async {
    final response = await _apiClient.put('/api/rooms/$roomId', body);
    if (response.statusCode != 200) {
      throw Exception('Cập nhật thông tin phòng thất bại.');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    final response = await _apiClient.delete('/api/rooms/$roomId');
    if (response.statusCode != 200) {
      throw Exception('Xóa phòng thất bại: ${response.body}');
    }
  }
}