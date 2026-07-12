import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_paginated_list.dart';
import '../../../../data/models/response/invoice_response.dart';
import 'invoice_detail_screen.dart';
import 'view_models/invoice_detail_view_model.dart';
import 'view_models/invoice_list_view_model.dart';

/// Màn hình Quản lý Hóa đơn dành cho Chủ trọ.
class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InvoiceListViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Quản lý Hóa đơn'),
      body: Column(
        children: [
          _buildSearchAndFilter(context, vm),
          Expanded(child: _buildBody(vm, context)),
        ],
      ),
    );
  }

  /// Khu vực thanh tìm kiếm và các chip lọc trạng thái
  Widget _buildSearchAndFilter(BuildContext context, InvoiceListViewModel vm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TextField Tìm kiếm
          TextField(
            onChanged: vm.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo số phòng...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Chips Lọc Trạng thái
          SingleChildScrollView(
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
        ],
      ),
    );
  }

  /// Danh sách hóa đơn sử dụng CustomPaginatedList
  Widget _buildBody(InvoiceListViewModel vm, BuildContext context) {
    return CustomPaginatedList<InvoiceResponse>(
      items: vm.displayedInvoices,
      isLoading: vm.isLoading,
      isFetchingMore: vm.isFetchingMore,
      errorMessage: vm.errorMessage,
      onRefresh: () async => await vm.fetchInvoices(isRefresh: true),
      onLoadMore: () => vm.fetchInvoices(isRefresh: false),
      itemBuilder: (context, invoice) => _buildInvoiceCard(context, invoice, vm),
    );
  }

  /// Item hiển thị thông tin tóm tắt của một Hóa đơn
  Widget _buildInvoiceCard(BuildContext context, InvoiceResponse invoice, InvoiceListViewModel vm) {
    final statusColor = _getStatusColor(invoice.status);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => InvoiceDetailViewModel()..fetchInvoiceDetail(invoice.id),
              child: const InvoiceDetailScreen(),
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Số phòng & Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phòng ${invoice.roomNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vm.statusMap[invoice.status] ?? invoice.status,
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
              // Body: Chi tiết thời gian & Tiền
              _buildInfoRow(Icons.calendar_today, 'Kỳ hóa đơn:', _formatDate(invoice.invoicePeriod)),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.event_busy, 'Hạn đóng:', _formatDate(invoice.dueDate)),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.monetization_on,
                'Tổng tiền:',
                '${_formatCurrency(invoice.totalAmount)} VNĐ',
                isHighlight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget hỗ trợ hiển thị 1 dòng thông tin (Icon + Label + Value)
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.redAccent : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // --- Utility Methods ---

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '---';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'UNPAID': return Colors.orange;
      case 'PAID': return Colors.green;
      case 'OVERDUE': return Colors.red;
      default: return Colors.grey;
    }
  }
}