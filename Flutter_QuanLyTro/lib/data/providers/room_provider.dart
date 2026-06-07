import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../models/response/room_model.dart';

class RoomProvider {
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

    throw Exception(
      'Không thể tải danh sách phòng',
    );
  }
}