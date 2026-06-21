import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/deposit_page/view_models/deposit_edit_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../data/models/response/deposit_response.dart';
import 'deposit_edit_screen.dart';
import 'view_models/deposit_detail_view_model.dart';

class DepositDetailScreen extends StatelessWidget {
  const DepositDetailScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Chưa cập nhật';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }



  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DepositDetailViewModel>();
    final deposit = vm.currentDeposit;

    if (deposit == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(title: 'Chi tiết phiếu cọc'),
      body: vm.isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'PHÒNG ${deposit.roomNumber}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: deposit.status == 'PENDING' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      deposit.status,
                      style: TextStyle(
                        color: deposit.status == 'PENDING' ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32, thickness: 1),
                _buildDetailRow('Khách thuê:', deposit.tenantFullName),
                _buildDetailRow('Số điện thoại:', deposit.phone),
                _buildDetailRow('Ngày lập phiếu:', _formatDate(deposit.depositDate)),
                _buildDetailRow('Dự kiến vào ở:', _formatDate(deposit.expectedMoveInDate)),
                _buildDetailRow('Ghi chú:', deposit.note ?? 'Không có'),
                const Divider(height: 32, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tiền cọc:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(
                      '${_formatCurrency(deposit.depositAmount)} VNĐ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ],
                ),
                if (vm.isDeleting || vm.isReloading)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final isUpdated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) => DepositEditViewModel()..initData(deposit),
                          child: const DepositEditScreen(),
                        ),
                      ),
                    );

                    // Nếu Edit thành công trả về true, gọi load lại
                    if (isUpdated == true && context.mounted) {
                      context.read<DepositDetailViewModel>().reloadDepositData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}