import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_paginated_list.dart';
import '../../../../data/models/response/issue_response.dart';
import 'issue_detail_screen.dart';
import 'report_issue_screen.dart';
import 'view_models/report_issue_view_model.dart';
import 'view_models/tenant_issue_list_view_model.dart';

class TenantIssueListScreen extends StatefulWidget {
  final String roomId;

  const TenantIssueListScreen({super.key, required this.roomId});

  @override
  State<TenantIssueListScreen> createState() => _TenantIssueListScreenState();
}

class _TenantIssueListScreenState extends State<TenantIssueListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantIssueListViewModel>().fetchIssues(isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TenantIssueListViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Danh sách sự cố'),
      body: Column(
        children: [
          _buildFilterChips(vm),
          Expanded(child: _buildBody(vm)),
        ],
      ),
      // --- NÚT DẤU CỘNG THÊM MỚI SỰ CỐ ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () async {
          // Điều hướng sang màn hình gửi báo cáo và chờ kết quả trả về
          final bool? isSuccess = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => ReportIssueViewModel(roomId: widget.roomId),
                child: const ReportIssueScreen(),
              ),
            ),
          );

          // Nếu gửi sự cố thành công, tự động làm mới danh sách
          if (isSuccess == true && mounted) {
            context.read<TenantIssueListViewModel>().fetchIssues(isRefresh: true);
          }
        },
      ),
    );
  }

  /// Bộ lọc trạng thái
  Widget _buildFilterChips(TenantIssueListViewModel vm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: vm.statusMap.entries.map((entry) {
            final isSelected = vm.selectedStatus == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                selectedColor: AppColors.primary.withOpacity(0.2),
                backgroundColor: Colors.grey[100],
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => vm.changeStatus(entry.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Khối nội dung quản lý phân trang danh sách sự cố
  Widget _buildBody(TenantIssueListViewModel vm) {
    return CustomPaginatedList<IssueResponse>(
      items: vm.issues,
      isLoading: vm.isLoading,
      isFetchingMore: vm.isFetchingMore,
      errorMessage: vm.errorMessage,
      onRefresh: () async => await vm.fetchIssues(isRefresh: true),
      onLoadMore: () => vm.fetchIssues(isRefresh: false),
      itemBuilder: (context, issue) => _buildIssueCard(context, issue),
    );
  }

  /// Khung hiển thị chi tiết thẻ sự cố
  Widget _buildIssueCard(BuildContext context, IssueResponse issue) {
    final statusColor = _getStatusColor(issue.status);
    final statusText = _getStatusText(issue.status);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueDetailScreen(issue: issue),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      issue.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày gửi:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(issue.createdAt),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Các hàm tiện ích bổ trợ ---
  String _formatDate(DateTime? date) {
    if (date == null) return '---';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return '---';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'ACCEPTED':
        return 'Đang xử lý';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      default:
        return status;
    }
  }
}