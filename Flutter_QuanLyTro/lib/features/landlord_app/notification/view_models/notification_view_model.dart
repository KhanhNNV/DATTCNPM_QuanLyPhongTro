import 'package:flutter/material.dart';
import '../../../../data/models/response/notification_model.dart';
import '../../../../data/repository/notification_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<NotificationModel> notifications = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  String? errorMessage;
  int unreadCount = 0;

  int _currentPage = 0;
  bool _hasMore = true;

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _hasMore = true;
    }

    isLoading = isRefresh ? false : true;
    notifyListeners();

    try {
      final data = await _repository.getMyNotifications(page: _currentPage, size: 20);
      final List<dynamic> content = data['content'] ?? [];
      final List<NotificationModel> newItems = content.map((json) => NotificationModel.fromJson(json)).toList();

      if (isRefresh) {
        notifications = newItems;
      } else {
        notifications.addAll(newItems);
      }

      _hasMore = newItems.length >= 20;
      await fetchUnreadCount();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Hàm load more
  Future<void> loadMore() async {
    if (isFetchingMore || !_hasMore) return;
    isFetchingMore = true;
    notifyListeners();

    _currentPage++;
    await fetchNotifications();
    isFetchingMore = false;
  }

  Future<void> fetchUnreadCount() async {
    try {
      unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (e) {
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);

      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !notifications[index].isRead) {
        notifications[index] = NotificationModel(
          id: notifications[index].id,
          title: notifications[index].title,
          content: notifications[index].content,
          type: notifications[index].type,
          isRead: true,
          createdAt: notifications[index].createdAt,
        );
        unreadCount = (unreadCount > 0) ? unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();

      notifications = notifications.map((n) {
        return NotificationModel(
            id: n.id, title: n.title, content: n.content,
            type: n.type, isRead: true, createdAt: n.createdAt
        );
      }).toList();

      unreadCount = 0;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}