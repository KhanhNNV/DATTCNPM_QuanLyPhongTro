import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'view_models/tenant_qr_payment_view_model.dart';

class TenantQrPaymentScreen extends StatelessWidget {
  const TenantQrPaymentScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TenantQrPaymentViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Thanh toán Hóa đơn'),
      body: _buildBody(vm, context),
    );
  }

  Widget _buildBody(TenantQrPaymentViewModel vm, BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: vm.fetchQrCode,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    final qrData = vm.qrResponse;
    if (qrData == null) {
      return const Center(child: Text('Không có dữ liệu mã QR.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text(
            'Quét mã QR để thanh toán',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Hình ảnh QR Code
          Container(
            width: 280,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                qrData.qrImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Không thể tải ảnh QR', textAlign: TextAlign.center),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Thông tin chuyển khoản
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                _buildQrInfoRow('Ngân hàng:', qrData.bankId),
                const Divider(),
                _buildQrInfoRow('Số TK:', qrData.accountNo, isCopyable: true, context: context),
                const Divider(),
                _buildQrInfoRow('Chủ TK:', qrData.accountName),
                const Divider(),
                _buildQrInfoRow(
                    'Số tiền:',
                    '${_formatCurrency(qrData.amount)} đ',
                    isHighlight: true
                ),
                const Divider(),
                _buildQrInfoRow('Nội dung:', qrData.content, isCopyable: true, context: context),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Dòng chú thích ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lưu ý: Sau khi chuyển khoản thành công, vui lòng chụp lại màn hình giao dịch và gửi ảnh bằng nút bên dưới để xác nhận.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.deepOrange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Nút Gửi ảnh xác nhận ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Triển khai chức năng chọn ảnh và gửi lên API ở đây
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng tải ảnh lên đang được cập nhật!')),
                );
              },
              icon: const Icon(Icons.upload_file, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              label: const Text(
                  'Gửi ảnh xác nhận',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildQrInfoRow(String label, String value, {bool isHighlight = false, bool isCopyable = false, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                      color: isHighlight ? Colors.redAccent : Colors.black87,
                      fontSize: isHighlight ? 16 : 14,
                    ),
                  ),
                ),
                if (isCopyable && context != null)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}