import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'view_models/invoice_detail_view_model.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
  }

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
      case 'UNPAID': return Colors.orange;
      case 'PAID': return Colors.green;
      case 'OVERDUE': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'UNPAID': return 'Chưa thanh toán';
      case 'PAID': return 'Đã thanh toán';
      case 'OVERDUE': return 'Quá hạn';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InvoiceDetailViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Chi tiết Hóa đơn'),
      body: _buildBody(vm, context),
    );
  }

  Widget _buildBody(InvoiceDetailViewModel vm, BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    final detail = vm.invoiceDetail;
    if (detail == null) {
      return const Center(child: Text('Không tìm thấy dữ liệu.'));
    }

    final statusColor = _getStatusColor(detail.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // THÔNG TIN CHUNG TÓM TẮT
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phòng ${detail.roomNumber}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(detail.status),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 30),
                  _buildRowInfo('Kỳ hóa đơn:', _formatDate(detail.invoicePeriod)),
                  const SizedBox(height: 8),
                  _buildRowInfo('Hạn thanh toán:', _formatDate(detail.dueDate)),
                  const SizedBox(height: 8),
                  _buildRowInfo('Tiền phòng gốc:', '${_formatCurrency(detail.roomPrice)} đ'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // CHI TIẾT DỊCH VỤ SỬ DỤNG
          const Text(
            'Chi tiết dịch vụ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias, // Để bo góc table
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                columns: const [
                  DataColumn(label: Text('Dịch vụ', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Chỉ số', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: detail.items.map((item) {
                  // Hiển thị chỉ số cũ - mới nếu có (Điện/Nước)
                  String indexDisplay = (item.oldIndex != null && item.newIndex != null)
                      ? '${item.oldIndex} -> ${item.newIndex}'
                      : '-';

                  return DataRow(cells: [
                    DataCell(Text(item.serviceName)),
                    DataCell(Text(indexDisplay)),
                    DataCell(Text('${item.quantity}')),
                    DataCell(Text(_formatCurrency(item.price))),
                    DataCell(Text(_formatCurrency(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // TỔNG TIỀN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG CỘNG:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_formatCurrency(detail.totalAmount)} VNĐ',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRowInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }
}