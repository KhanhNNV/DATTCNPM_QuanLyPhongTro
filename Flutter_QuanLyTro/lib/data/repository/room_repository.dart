import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../models/response/room_model.dart';
import '../../../core/utils/api_error_handler.dart'; // Import bộ xử lý lỗi

class RoomRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<RoomModel>> getRoomsByArea(
      String areaId, {
        String? status,
      }) async {
    String endpoint = '/api/rooms/area/$areaId';

    if (status != null) {
      endpoint += '?status=$status';
    }

    final response = await _apiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      return data
          .map((json) => RoomModel.fromJson(json))
          .toList();
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<RoomModel> getRoomById(String roomId) async {
    final response = await _apiClient.get('/api/rooms/$roomId');

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return RoomModel.fromJson(json);
    }
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}