import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/tenant_app/invoices/tenant_invoice_detail_screen.dart';
import 'package:flutter_quanlytro/features/tenant_app/invoices/view_models/tenant_invoice_detail_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_paginated_list.dart';
import '../../../../data/models/response/invoice_response.dart';
import 'view_models/tenant_invoice_list_view_model.dart';
// Import file Detail nếu bạn muốn nhấn vào để xem chi tiết
// import 'tenant_invoice_detail_screen.dart';

class TenantInvoiceListScreen extends StatelessWidget {
  const TenantInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TenantInvoiceListViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Hóa đơn của tôi'),
      body: Column(
        children: [
          _buildFilterChips(vm),
          Expanded(child: _buildBody(vm, context)),
        ],
      ),
    );
  }

  /// Danh sách các nút chọn trạng thái (Tất cả, Chưa thanh toán...)
  Widget _buildFilterChips(TenantInvoiceListViewModel vm) {
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

  /// Body chứa danh sách hóa đơn có phân trang
  Widget _buildBody(TenantInvoiceListViewModel vm, BuildContext context) {
    return CustomPaginatedList<InvoiceResponse>(
      items: vm.invoices,
      isLoading: vm.isLoading,
      isFetchingMore: vm.isFetchingMore,
      errorMessage: vm.errorMessage,
      onRefresh: () async => await vm.fetchInvoices(isRefresh: true),
      onLoadMore: () => vm.fetchInvoices(isRefresh: false),
      itemBuilder: (context, invoice) => _buildInvoiceCard(context, invoice),
    );
  }

  /// Card hiển thị từng hóa đơn
  Widget _buildInvoiceCard(BuildContext context, InvoiceResponse invoice) {
    final statusColor = _getStatusColor(invoice.status);
    final statusText = _getStatusText(invoice.status);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => TenantInvoiceDetailViewModel()..fetchInvoiceDetail(invoice.id),
              child: const TenantInvoiceDetailScreen(),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kỳ tháng ${_formatMonth(invoice.invoicePeriod)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
              // Body
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

  // --- Utils ---
  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '---';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateString));
    } catch (_) {
      return dateString;
    }
  }

  String _formatMonth(String dateString) {
    if (dateString.isEmpty) return '---';
    try {
      return DateFormat('MM/yyyy').format(DateTime.parse(dateString));
    } catch (_) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'UNPAID': return Colors.orange;
      case 'PAID': return Colors.green;
      case 'OVERDUE': return Colors.red;
      case 'PENDING': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'UNPAID': return 'Chưa thanh toán';
      case 'PAID': return 'Đã thanh toán';
      case 'OVERDUE': return 'Quá hạn';
      case 'PENDING': return 'Chờ xác nhận';
      default: return status;
    }
  }
}