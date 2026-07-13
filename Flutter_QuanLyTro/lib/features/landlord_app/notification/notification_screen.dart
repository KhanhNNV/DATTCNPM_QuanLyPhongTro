import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/response/notification_model.dart';
import '../../../core/widgets/custom_paginated_list.dart';
import 'view_models/notification_view_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông báo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cập nhật các thông tin mới nhất',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (viewModel.unreadCount > 0)
                    TextButton(
                      onPressed: viewModel.markAllAsRead,
                      child: const Text(
                        'Đã đọc tất cả',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),


            Expanded(
              child: CustomPaginatedList<NotificationModel>(
                items: viewModel.notifications,
                isLoading: viewModel.isLoading,
                isFetchingMore: viewModel.isFetchingMore,
                errorMessage: viewModel.errorMessage,
                onLoadMore: () => viewModel.loadMore(),
                onRefresh: () => viewModel.fetchNotifications(isRefresh: true),
                emptyWidget: const Center(child: Text('Bạn chưa có thông báo nào.')),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, noti) {
                  final isUnread = !noti.isRead;

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      onTap: () {
                        if (isUnread) viewModel.markAsRead(noti.id);
                      },
                      leading: CircleAvatar(
                        backgroundColor: isUnread
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.1),
                        child: Icon(
                          Icons.notifications,
                          color: isUnread ? AppColors.primary : Colors.grey,
                        ),
                      ),
                      title: Text(
                        noti.title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(noti.content),
                          const SizedBox(height: 6),
                          Text(
                            noti.createdAt.split('T').join(' ').substring(0, 16),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      trailing: isUnread
                          ? const CircleAvatar(radius: 5, backgroundColor: Colors.blue)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}