import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/issues/view_models/landlord_issue_detail_view_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_paginated_list.dart';
import '../../../../data/models/response/issue_response.dart';
import 'landlord_issue_detail_screen.dart';
import 'view_models/landlord_issue_list_view_model.dart';

class LandlordIssueListScreen extends StatefulWidget {
  const LandlordIssueListScreen({super.key});

  @override
  State<LandlordIssueListScreen> createState() => _LandlordIssueListScreenState();
}

class _LandlordIssueListScreenState extends State<LandlordIssueListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LandlordIssueListViewModel>().fetchIssues(isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandlordIssueListViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Quản lý sự cố'),
      body: Column(
        children: [
          _buildFilterChips(vm),
          Expanded(child: _buildBody(vm)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(LandlordIssueListViewModel vm) {
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

  Widget _buildBody(LandlordIssueListViewModel vm) {
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

  Widget _buildIssueCard(BuildContext context, IssueResponse issue) {
    final statusColor = _getStatusColor(issue.status);
    final statusText = _getStatusText(issue.status);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final bool? hasChanged = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => LandlordIssueDetailViewModel(currentIssue: issue),
                child: const LandlordIssueDetailScreen(),
              ),
            ),
          );

          if (hasChanged == true && context.mounted) {
            context.read<LandlordIssueListViewModel>().fetchIssues(isRefresh: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Phòng ${issue.roomNumber}',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
              const SizedBox(height: 12),
              Text(
                issue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF263238),
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    issue.tenantName,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(issue.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '---';
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return '---';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING': return 'Chờ xử lý';
      case 'ACCEPTED': return 'Đang xử lý';
      case 'COMPLETED': return 'Đã hoàn thành';
      default: return status;
    }
  }
}