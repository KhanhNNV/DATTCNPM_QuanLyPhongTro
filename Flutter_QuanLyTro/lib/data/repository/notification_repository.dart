import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../core/utils/api_error_handler.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getMyNotifications({
    required int page,
    required int size,
  }) async {
    final path = '/api/notifications?page=$page&size=$size';
    final response = await _apiClient.get(path);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<int> getUnreadCount() async {
    final path = '/api/notifications/unread-count';
    final response = await _apiClient.get(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['unreadCount'] ?? 0;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> markAsRead(String id) async {
    final path = '/api/notifications/$id/read';
    final response = await _apiClient.put(path, {});

    if (response.statusCode == 200) {
      return;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<void> markAllAsRead() async {
    final path = '/api/notifications/read-all';
    final response = await _apiClient.put(path, {});

    if (response.statusCode == 200) {
      return;
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}