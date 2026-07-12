import 'package:flutter/material.dart';

/// Widget danh sách dùng chung hỗ trợ phân trang (Load more) và Làm mới (Pull-to-refresh).
/// Sử dụng Generic Type [T] để tái sử dụng cho nhiều loại model khác nhau.
class CustomPaginatedList<T> extends StatelessWidget {
  final List<T> items;
  final bool isLoading;
  final bool isFetchingMore;
  final String? errorMessage;
  final VoidCallback onLoadMore;
  final Future<void> Function()? onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;

  const CustomPaginatedList({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isFetchingMore,
    required this.onLoadMore,
    required this.itemBuilder,
    this.errorMessage,
    this.onRefresh,
    this.emptyWidget,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Trạng thái tải dữ liệu lần đầu
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Trạng thái lỗi ở lần tải đầu tiên
    if (errorMessage != null && items.isEmpty) {
      return _buildErrorState();
    }

    // 3. Trạng thái danh sách trống
    if (items.isEmpty) {
      return emptyWidget ??
          const Center(
            child: Text(
              'Không có dữ liệu.',
              style: TextStyle(color: Colors.grey),
            ),
          );
    }

    // 4. Trạng thái hiển thị danh sách
    Widget listView = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.separated(
        padding: padding ?? const EdgeInsets.all(16),
        itemCount: items.length + (isFetchingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // Hiển thị loading indicator ở cuối danh sách khi đang fetch more
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return itemBuilder(context, items[index]);
        },
      ),
    );

    // Bọc RefreshIndicator nếu có hỗ trợ pull-to-refresh
    return onRefresh != null
        ? RefreshIndicator(onRefresh: onRefresh!, child: listView)
        : listView;
  }

  /// Lắng nghe sự kiện cuộn để kích hoạt tải thêm dữ liệu khi gần chạm đáy
  bool _handleScrollNotification(ScrollNotification scrollInfo) {
    if (!isLoading && !isFetchingMore) {
      final metrics = scrollInfo.metrics;
      // Kích hoạt load more khi cách đáy 50 pixels
      if (metrics.pixels >= metrics.maxScrollExtent - 50) {
        onLoadMore();
      }
    }
    return false;
  }

  /// Giao diện hiển thị khi lỗi tải trang đầu tiên
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          if (onRefresh != null)
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Thử lại'),
            ),
        ],
      ),
    );
  }
}