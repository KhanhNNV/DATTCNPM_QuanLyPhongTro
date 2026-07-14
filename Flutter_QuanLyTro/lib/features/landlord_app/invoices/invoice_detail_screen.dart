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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InvoiceDetailViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Chi tiết Hóa đơn'),
      body: _buildBody(vm, context),
      bottomNavigationBar: _buildBottomAction(vm, context),
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

          const Text(
            'Chi tiết dịch vụ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                columns: const [
                  DataColumn(label: Text('Dịch vụ', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Chỉ số', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: detail.items.map((item) {

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

  Widget? _buildBottomAction(InvoiceDetailViewModel vm, BuildContext context) {
    final detail = vm.invoiceDetail;

    if (detail == null || detail.paymentProofUrl == null || detail.paymentProofUrl!.isEmpty) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          icon: const Icon(Icons.receipt_long, color: Colors.white),
          label: const Text(
            'Xem minh chứng thanh toán',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          onPressed: () {
            _showProofDialog(context, vm, detail.id, detail.paymentProofUrl!, detail.status);
          },
        ),
      ),
    );
  }

  void _showProofDialog(BuildContext context, InvoiceDetailViewModel vm, String invoiceId, String imageUrl, String status) {
    showDialog(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final isPending = status == 'PENDING';

        return AlertDialog(
          title: const Text('Minh chứng thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: size.height * 0.6,
              maxWidth: double.maxFinite,
            ),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Không thể tải ảnh', style: TextStyle(color: Colors.red)),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
          ),
          actionsAlignment: isPending ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,

          actions: isPending
              ? [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showRejectDialog(context, vm, invoiceId);
              },
              child: const Text('Từ chối'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(ctx);

                String? errorMsg = await vm.confirmPayment(invoiceId);

                if (context.mounted) {
                  if (errorMsg == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xác nhận thanh toán thành công!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ]
              : [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
            )
          ],
        );
      },
    );
  }


  void _showRejectDialog(BuildContext context, InvoiceDetailViewModel vm, String invoiceId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Lý do từ chối', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do từ chối thanh toán...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                String reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lý do từ chối!'), backgroundColor: Colors.orange),
                  );
                  return;
                }

                Navigator.pop(ctx);


                String? errorMsg = await vm.rejectPayment(invoiceId, reason);

                if (context.mounted) {
                  if (errorMsg == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã từ chối thanh toán.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Gửi', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}