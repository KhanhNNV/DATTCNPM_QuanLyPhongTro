import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'view_models/invoice_list_view_model.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
  }

  // Chuyển đổi chuỗi ngày yyyy-MM-dd sang dd/MM/yyyy
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '---';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'UNPAID':
        return Colors.orange;
      case 'PAID':
        return Colors.green;
      case 'OVERDUE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

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

  Widget _buildSearchAndFilter(BuildContext context, InvoiceListViewModel vm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh tìm kiếm
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
          // Thanh chọn trạng thái
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
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
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

  Widget _buildBody(InvoiceListViewModel vm, BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => vm.fetchInvoices(),
              child: const Text('Thử lại'),
            )
          ],
        ),
      );
    }

    if (vm.displayedInvoices.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy hóa đơn nào.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vm.displayedInvoices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invoice = vm.displayedInvoices[index];
        final statusColor = _getStatusColor(invoice.status);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phòng ${invoice.roomNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vm.statusMap[invoice.status] ?? invoice.status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
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
        );
      },
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
}